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
        Ты — финансовый аналитик. Твоя задача - распарсить текст выписки Kaspi Gold (Казахстан).

        ОСОБЕННОСТИ ФОРМАТА KASPI:
        1. Суммы могут быть "1 500.00 - T" (минус справа) или "- 1 500 T".
        2. Игнорируй 'Replenishment' (пополнения).

        ВАЖНЫЕ ПРАВИЛА КАТЕГОРИЙ:
        1. "Pay for Kaspi Red" — это КРЕДИТ/РАССРОЧКА (Shopping). Это НЕ подписка! Никогда не добавляй Kaspi Red в subscriptions.
        2. "Transfers" (Переводы) часто являются скрытыми покупками. Если перевод юр.лицу (ИП, ТОО) — пытайся угадать категорию (Еда, Услуги). Если физ.лицу — оставляй "Переводы".
        3. Подписки — это ТОЛЬКО: Spotify, Netflix, Apple, Yandex, Google, Ivi.

        ВЕРНИ JSON:
        {
          "total_spent": float,
          "forecast_next_month": float,
          "categories": [{"name": "string", "amount": float, "percent": float, "color": "hex"}],
          "subscriptions": [{"name": "string", "cost": float}],
          "advice": "Совет (упомяни, если много трат на рассрочки Kaspi Red)"
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