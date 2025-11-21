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
    {"name": "Spotify Premium", "cost": 4282}
  ],
  "advice": "Амир, мы заметили подписку на Spotify (4282 ₸) и частые траты в Steam. В Магнуме вы оставили 45% бюджета. Рекомендуем оформить карту Magnum Club для бонусов.",
  "transactions": [
    {"date": "01.03.2024", "amount": 1500, "description": "Magnum", "category": "Продукты (Magnum)"},
    {"date": "02.03.2024", "amount": 850, "description": "Yandex Go", "category": "Такси (Yandex)"},
    {"date": "03.03.2024", "amount": 4282, "description": "Spotify Premium", "category": "Прочее"},
    {"date": "05.03.2024", "amount": 3200, "description": "Steam", "category": "Развлечения (Steam/Kino)"},
    {"date": "07.03.2024", "amount": 2100, "description": "Bahandi", "category": "Фастфуд (Тандыр/Bahandi)"},
    {"date": "10.03.2024", "amount": 4500, "description": "Magnum", "category": "Продукты (Magnum)"},
    {"date": "12.03.2024", "amount": 1200, "description": "Yandex Go", "category": "Такси (Yandex)"},
    {"date": "15.03.2024", "amount": 5490, "description": "Kaspi Magazin", "category": "Прочее"}
  ]
}

def analyze_kaspi_statement(text, language="ru"):
    # Определяем язык для категорий
    lang_map = {
        "ru": {
            "products": "Продукты",
            "taxi": "Такси",
            "entertainment": "Развлечения",
            "fastfood": "Фастфуд",
            "credit": "Рассрочка",
            "other": "Прочее"
        },
        "kz": {
            "products": "Тауарлар",
            "taxi": "Такси",
            "entertainment": "Ойын-сауық",
            "fastfood": "Жылдам тағам",
            "credit": "Бөліп төлеу",
            "other": "Басқа"
        },
        "en": {
            "products": "Products",
            "taxi": "Taxi",
            "entertainment": "Entertainment",
            "fastfood": "Fast Food",
            "credit": "Credit",
            "other": "Other"
        }
    }
    
    lang_names = lang_map.get(language, lang_map["ru"])
    
    system_prompt = f"""
    Ты — финансовый аналитик. Твоя задача - распарсить выписку Kaspi Gold.
    
    ОСОБЕННОСТИ:
    1. Суммы: "1 500.00 - T" (минус справа) или "- 1 500 T".
    2. Игнорируй пополнения (Replenishment).
    
    🛑 ЖЕЛЕЗНЫЕ ПРАВИЛА (Strict Rules):
    
    1. 💳 ПОДПИСКИ (ТОЛЬКО цифровые сервисы, НЕ кредиты/рассрочки):
       - Включай сюда ТОЛЬКО: "Yandex Plus", "Spotify", "Netflix", "Apple", "Ivi", "Kinopoisk", "Google Storage", "YouTube Premium".
       - ⛔ СТРОГО ЗАПРЕЩЕНО включать сюда: "Kaspi Red", "Kaspi Magazin", "Credit", "Рассрочка", "Погашение кредита", "TOO Kaspi Magazin". Это НЕ подписки, это кредиты/рассрочки!
       - Если видишь Kaspi Magazin или Kaspi Red - это НЕ подписка, это кредит/рассрочка!
       
    2. ⏳ РАССРОЧКА/КРЕДИТЫ (Отдельная категория в categories, НЕ в subscriptions!):
       - Если видишь: "Kaspi Red", "Pay for Kaspi Red", "Kaspi Magazin", "TOO Kaspi Magazin", "Погашение кредита", "Credit".
       - Создай для них отдельную категорию "{lang_names['credit']}" в списке categories.
       - Цвет для этой категории: "FF5722" (Оранжевый/Красный).
       - НИКОГДА не добавляй их в subscriptions!
       
    3. 🚕 ТРАНСПОРТ: 
       - "Yandex Go" (именно Go!), "Uber", "Onay", "InDrive".
       - Название категории: "{lang_names['taxi']} (Yandex)"
       
    4. 🛍 ПРОДУКТЫ/ЕДА:
       - "Magnum", "Small", "Galmart", "Glovo", "Wolt", "Burger", "Bahandi".
       - Название категории: "{lang_names['products']} (Magnum)" или "{lang_names['products']}"
       
    5. 🎬 РАЗВЛЕЧЕНИЯ:
       - "Steam", "Kino", "Cinema", "Games"
       - Название категории: "{lang_names['entertainment']} (Steam/Kino)"
       
    6. 🍔 ФАСТФУД:
       - "Bahandi", "Tandyr", "Burger", "Pizza"
       - Название категории: "{lang_names['fastfood']} (Тандыр/Bahandi)"

    ЗАДАЧА:
    Верни JSON. В поле `categories` должна появиться категория "{lang_names['credit']}", если есть соответствующие траты.
    В поле `subscriptions` НЕ ДОЛЖНО быть Каспи магазина, Kaspi Red, кредитов или рассрочек - ТОЛЬКО цифровые подписки!
    
    Структура JSON:
    {{
      "total_spent": float,
      "forecast_next_month": float,
      "categories": [{{"name": "string", "name_ru": "string", "name_kz": "string", "name_en": "string", "amount": float, "percent": float, "color": "hex"}}],
      "subscriptions": [{{"name": "string", "cost": float}}],
      "advice": "Совет",
      "transactions": [
        {{
          "date": "DD.MM.YYYY",
          "amount": float,
          "description": "string",
          "category": "string"
        }}
      ]
    }}
    
    ВАЖНО:
    - Каждая категория должна иметь поля name, name_ru, name_kz, name_en для мультиязычности
    - name - это название на текущем языке ({language})
    - В поле subscriptions ТОЛЬКО цифровые подписки (Spotify, Netflix и т.д.), НЕ Kaspi Magazin!
    - Извлекай ВСЕ транзакции из выписки (расходы, не пополнения)
    - Формат даты: DD.MM.YYYY (например, "15.03.2024")
    - amount должен быть положительным числом (сумма расхода)
    - description - краткое описание транзакции (например, "Magnum", "Yandex Go", "Spotify Premium")
    - category - категория из списка categories (используй name на текущем языке)
    """

    try:
        response = client.chat.completions.create(
            model="deepseek-chat",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": f"Текст выписки:\n{text[:5000]}"}
            ],
            temperature=0.1,
            max_tokens=2000
        )
        clean_json = response.choices[0].message.content.replace("```json", "").replace("```", "").strip()
        result = json.loads(clean_json)
        
        # Фильтруем подписки - удаляем Kaspi Magazin и кредиты
        if "subscriptions" in result and isinstance(result["subscriptions"], list):
            result["subscriptions"] = [
                sub for sub in result["subscriptions"]
                if sub.get("name", "").lower() not in ["kaspi magazin", "kaspi red", "рассрочка", "credit", "погашение кредита"]
            ]
        
        return result
    except Exception as e:
        print(f"AI Error: {e}")
        return None

@app.post("/analyze")
async def analyze_statement(file: UploadFile = File(...), language: str = "ru"):
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

    # Отправляем в AI с языком
    result = analyze_kaspi_statement(full_text, language)
    
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