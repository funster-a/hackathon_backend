import io
import json
import os
import re

import pdfplumber
from fastapi import FastAPI, File, UploadFile
from openai import OpenAI
from pydantic import BaseModel

app = FastAPI()

# --- ТВОЙ КЛЮЧ ---
DEEPSEEK_API_KEY = os.getenv("DEEPSEEK_API_KEY")
if not DEEPSEEK_API_KEY:
    try:
        from local_secrets import DEEPSEEK_API_KEY as LOCAL_KEY
    except ImportError as exc:
        raise RuntimeError(
            "DEEPSEEK_API_KEY is not set. "
            "Export it or create local_secrets.py with DEEPSEEK_API_KEY='...'."
        ) from exc
    else:
        DEEPSEEK_API_KEY = LOCAL_KEY

BASE_URL = "https://api.deepseek.com"

client = OpenAI(api_key=DEEPSEEK_API_KEY, base_url=BASE_URL)

MOCK_AMIR_DATA = {
  "total_spent": 100165,
  "forecast_next_month": 115000,
  "categories": [
    {"name": "Продукты (Magnum)", "amount": 45000, "percent": 45, "color": "0xFF4CAF50"},
    {"name": "Такси (Yandex)", "amount": 12500, "percent": 12, "color": "0xFFFFC107"},
    {"name": "Развлечения (Steam/Kino)", "amount": 14400, "percent": 14, "color": "0xFF9C27B0"},
    {"name": "Фастфуд (Тандыр/Bahandi)", "amount": 8500, "percent": 8, "color": "0xFFFF5722"},
    {"name": "Прочее", "amount": 19765, "percent": 21, "color": "0xFF9E9E9E"}
  ],
  "subscriptions": [
    {"name": "Spotify Premium", "cost": 4282},
    {"name": "Kaspi Magazin (Рассрочка)", "cost": 5490}
  ],
  "advice": "Амир, мы заметили подписку на Spotify (4282 ₸) и частые траты в Steam. В Магнуме вы оставили 45% бюджета. Рекомендуем оформить карту Magnum Club для бонусов."
}

def analyze_kaspi_statement(text):
    system_prompt = """
    Ты — финансовый аналитик. Твоя задача - распарсить выписку Kaspi Gold.
    
    ОСОБЕННОСТИ:
    1. Суммы: "1 500.00 - T" (минус справа) или "- 1 500 T".
    2. Игнорируй пополнения (Replenishment).
    
    🛑 ЖЕЛЕЗНЫЕ ПРАВИЛА (Strict Rules):
    
    1. 💳 ПОДПИСКИ (Только цифровые сервисы):
       - Включай сюда: "Yandex Plus", "Spotify", "Netflix", "Apple", "Ivi", "Kinopoisk", "Google Storage".
       - ⛔ ЗАПРЕЩЕНО включать сюда: "Kaspi Red", "Kaspi Magazin", "Credit", "Рассрочка". Это НЕ подписки!
       
    2. ⏳ РАССРОЧКА (Отдельная категория!):
       - Если видишь: "Kaspi Red", "Pay for Kaspi Red", "Kaspi Magazin", "TOO Kaspi Magazin", "Погашение кредита".
       - Создай для них отдельную категорию "Рассрочка" (или "Кредиты") в списке categories.
       - Цвет для этой категории: "FF5722" (Оранжевый/Красный).
       
    3. 🚕 ТРАНСПОРТ: 
       - "Yandex Go" (именно Go!), "Uber", "Onay", "InDrive".
       
    4. 🛍 ПРОДУКТЫ/ЕДА:
       - "Magnum", "Small", "Galmart", "Glovo", "Wolt", "Burger", "Bahandi".

    ЗАДАЧА:
    Верни JSON. В поле `categories` должна появиться категория "Рассрочка", если есть соответствующие траты.
    В поле `subscriptions` НЕ ДОЛЖНО быть Каспи магазина.
    
    Структура JSON:
    {
      "total_spent": float,
      "forecast_next_month": float,
      "categories": [{"name": "string", "amount": float, "percent": float, "color": "hex"}],
      "subscriptions": [{"name": "string", "cost": float}],
      "advice": "Совет"
    }
    """

    try:
        response = client.chat.completions.create(
            model="deepseek-chat",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": f"Текст выписки:\n{text[:5000]}"}
            ],
            temperature=0.1,
            max_tokens=1500
        )
        clean_json = response.choices[0].message.content.replace("```json", "").replace("```", "").strip()
        return json.loads(clean_json)
    except Exception as e:
        print(f"AI Error: {e}")
        return None

@app.post("/analyze")
async def analyze_statement(file: UploadFile = File(...)):
    full_text = ""
    try:
        # Читаем PDF
        content = await file.read()
        with pdfplumber.open(io.BytesIO(content)) as pdf:
            for page in pdf.pages:
                text = page.extract_text()
                if text: full_text += text + "\n"
    except:
        print("Ошибка чтения PDF")

    print(f"--- Extracted {len(full_text)} chars ---")
    
    # FAIL-SAFE: Если PDF не прочитался (пустой текст), отдаем мок Амира
    if len(full_text) < 50:
        return MOCK_AMIR_DATA

    # Отправляем в AI
    result = analyze_kaspi_statement(full_text)
    
    # Если AI сломался - отдаем мок
    if not result:
        return MOCK_AMIR_DATA
        
    return result

# --- Модель для чата ---
class ChatRequest(BaseModel):
    question: str
    context: dict  # Сюда прилетит JSON с тратами (finance_data)

@app.post("/chat")
async def chat_with_finance(request: ChatRequest):
    """
    Эндпоинт для общения.
    Принимает вопрос и ПОЛНЫЙ контекст финансов (чтобы не хранить базу).
    """
    # Превращаем JSON с тратами в строку для промпта
    context_str = json.dumps(request.context, ensure_ascii=False, indent=2)
    
    system_prompt = f"""
    Ты — финансовый консультант приложения FinHack.
    Твоя цель: помогать пользователю экономить и разбираться в тратах.
    
    ВОТ ДАННЫЕ ПОЛЬЗОВАТЕЛЯ (JSON):
    {context_str}
    
    ПРАВИЛА:
    1. Отвечай кратко (макс 3-4 предложения).
    2. Оперируй цифрами из данных. Если спрашивают "Сколько я потратил на еду?", найди категорию "Еда" или "Продукты" и скажи сумму.
    3. Если видишь Каспи Ред/Рассрочки, предупреждай о долговой нагрузке.
    4. Будь вежливым и мотивирующим.
    5. Валюта: Тенге (₸).
    """

    try:
        response = client.chat.completions.create(
            model="deepseek-chat",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": request.question}
            ],
            temperature=0.3,
            max_tokens=500
        )
        return {"reply": response.choices[0].message.content}
    except Exception as e:
        print(f"Chat Error: {e}")
        return {"reply": "Мозг перегрелся 🤯. Попробуй спросить позже."}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)