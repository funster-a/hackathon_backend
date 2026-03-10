import json
import os
import re
from fastapi import FastAPI
from openai import OpenAI
from pydantic import BaseModel

app = FastAPI()

# --- API КЛЮЧ (Groq) ---
GROQ_API_KEY = os.getenv("GROQ_API_KEY")
if not GROQ_API_KEY:
    try:
        from local_secrets import GROQ_API_KEY as LOCAL_KEY
        GROQ_API_KEY = LOCAL_KEY
    except ImportError as exc:
        raise RuntimeError(
            "GROQ_API_KEY is not set. "
            "Export it or create local_secrets.py with GROQ_API_KEY='...'."
        ) from exc

# Используем клиент OpenAI, но направляем его на быстрые серверы Groq
BASE_URL = "https://api.groq.com/openai/v1"
client = OpenAI(api_key=GROQ_API_KEY, base_url=BASE_URL)
MODEL_NAME = "llama-3.3-70b-versatile"

class StartupRequest(BaseModel):
    description: str

class ChatRequest(BaseModel):
    question: str
    context: dict
    user_goal: str = ""
    language: str = "ru"

@app.post("/analyze_startup")
async def analyze_startup(request: StartupRequest, language: str = "ru"):
    """Анализирует идею стартапа и возвращает примерную смету для MVP"""
    
    system_prompt = f"""
    Ты — опытный трекер стартапов и CTO. Твоя задача — оценить стоимость создания MVP для описанной идеи на первые 3 месяца.
    Язык ответа: {language}. Оперируй валютой: Тенге (₸).

    ОБЯЗАТЕЛЬНО верни ТОЛЬКО валидный JSON со следующей структурой (без markdown и комментариев):
    {{
      "total_budget": float (общий бюджет на 3 месяца),
      "monthly_burn_rate": float (ежемесячные расходы),
      "runway_months": int (укажи 3),
      "advice": "Твой краткий стратегический совет по MVP",
      "categories": [
        {{"name": "Разработка", "amount": float, "percent": float, "color": "FF4CAF50"}},
        {{"name": "Инфраструктура", "amount": float, "percent": float, "color": "FF2196F3"}},
        {{"name": "Маркетинг", "amount": float, "percent": float, "color": "FFFFC107"}},
        {{"name": "Прочее", "amount": float, "percent": float, "color": "FF9E9E9E"}}
      ],
      "team": [
        {{"role": "Frontend Developer", "stack": "React/Flutter", "salary": float}},
        {{"role": "Backend Developer", "stack": "Python/Go", "salary": float}}
      ]
    }}
    """

    try:
        response = client.chat.completions.create(
            model=MODEL_NAME,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": f"Идея стартапа: {request.description}"}
            ],
            temperature=0.2,
            response_format={"type": "json_object"} # Заставляем Groq отдать строгий JSON
        )
        
        raw_content = response.choices[0].message.content
        return json.loads(raw_content)
        
    except Exception as e:
        print(f"Error: {e}")
        # Фоллбэк (Mock), если API недоступно
        return {
            "total_budget": 5000000,
            "monthly_burn_rate": 1600000,
            "runway_months": 3,
            "advice": "API недоступно. Это пример расчетов. Сфокусируйтесь на быстрой проверке гипотез.",
            "categories": [
                {"name": "Команда", "amount": 3000000, "percent": 60, "color": "FF4CAF50"},
                {"name": "Серверы", "amount": 500000, "percent": 10, "color": "FF2196F3"},
                {"name": "Маркетинг", "amount": 1500000, "percent": 30, "color": "FFFFC107"}
            ],
            "team": [
                {"role": "Fullstack Dev", "stack": "React + Go", "salary": 800000},
                {"role": "Marketing Specialist", "stack": "Ads", "salary": 400000}
            ]
        }

@app.post("/chat")
async def chat_with_mentor(request: ChatRequest):
    """Эндпоинт для общения с AI-ментором"""
    context_str = json.dumps(request.context, ensure_ascii=False, indent=2)
    
    goal_prompt = f"\nБизнес-цель: {request.user_goal}." if request.user_goal else ""
    
    system_prompt = f"""
    Ты — технический директор и AI-ментор по стартапам.
    Язык ответа: {request.language}.
    
    СМЕТА ПРОЕКТА:
    {context_str}
    {goal_prompt}
    
    ПРАВИЛА:
    1. Отвечай кратко, как опытный фаундер (макс 3-4 предложения).
    2. Оперируй цифрами из сметы.
    3. Давай практичные советы по архитектуре (предлагай использовать современные инструменты, например Go для бэкенда, React/Flutter для фронта).
    4. Предостерегай от лишних трат на старте.
    """

    try:
        response = client.chat.completions.create(
            model=MODEL_NAME,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": request.question}
            ],
            temperature=0.5,
            max_tokens=300
        )
        return {"reply": response.choices[0].message.content}
    except Exception as e:
        print(f"Chat Error: {e}")
        return {"reply": "Серверы перегружены, обдумываю архитектуру 🤯. Попробуй позже."}

if __name__ == "__main__":
    import uvicorn
    print("🚀 Запуск сервера стартап-ментора на http://0.0.0.0:8000")
    uvicorn.run(app, host="0.0.0.0", port=8000)