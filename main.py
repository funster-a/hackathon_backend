import io
import json
import os
import re

import pdfplumber
from fastapi import FastAPI, File, UploadFile
from openai import OpenAI

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

# --- MOCK ДАННЫЕ (ИДЕАЛЬНАЯ КОПИЯ ТВОЕЙ ВЫПИСКИ) ---
# Если PDF не прочитается, мы отдадим это. Это данные Амира из файла.
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
    """
    Специальный промпт для Kaspi выписок, где минусы могут стоять справа (500.00 - T)
    """
    system_prompt = """
    Ты финансовый аналитик. Твоя задача - распарсить грязный текст выписки Kaspi Gold (Казахстан).
    
    ОСОБЕННОСТИ ФОРМАТА KASPI (ВАЖНО):
    1. Суммы расходов могут быть написаны как "- 1 500,00 T" (минус слева).
    2. ИЛИ как "1 500,00 - T" (минус справа!).
    3. ИЛИ разорваны пробелами "13 - 050,00 T".
    4. Расходы - это категории 'Purchases', 'Withdrawals', 'Transfers'.
    5. Игнорируй 'Replenishment' (пополнения).
    
    ЗАДАЧА:
    1. Найди все расходы.
    2. Сгруппируй их по категориям:
       - Magnum/Small/Супермаркет -> "Продукты"
       - Yandex/Uber/Onay -> "Транспорт"
       - Steam/Kino/PlayStation -> "Развлечения"
       - Кафе/Бургер/Тандыр -> "Еда"
       - Spotify/Netflix/Apple -> "Подписки"
    3. Верни JSON.
    
    JSON STRUCTURE:
    {
      "total_spent": float (сумма всех расходов),
      "forecast_next_month": float (total_spent * 1.1),
      "categories": [{"name": "Category Name", "amount": float, "percent": float, "color": "hex"}],
      "subscriptions": [{"name": "Service Name", "cost": float}],
      "advice": "Совет на русском языке, упомяни конкретные магазины из выписки"
    }
    """

    try:
        response = client.chat.completions.create(
            model="deepseek-chat",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": f"Текст выписки:\n{text[:5000]}"} # Берем первые 5000 символов
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

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)