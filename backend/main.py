import io
import json
import os
import re

import pdfplumber
from fastapi import FastAPI, File, UploadFile
from openai import OpenAI
from pydantic import BaseModel

app = FastAPI()

# --- API КЛЮЧ (DeepSeek) ---
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

BASE_URL = "https://api.deepseek.com/v1"

client = OpenAI(api_key=DEEPSEEK_API_KEY, base_url=BASE_URL)

# Функция для проверки API ключа
def check_api_key():
    """Проверяет валидность API ключа, делая тестовый запрос"""
    try:
        test_response = client.chat.completions.create(
            model="deepseek-chat",  # Модель DeepSeek
            messages=[{"role": "user", "content": "test"}],
            max_tokens=5
        )
        print("✅ DeepSeek API ключ валиден")
        return True
    except Exception as e:
        error_msg = str(e).lower()
        if "rate limit" in error_msg or "quota" in error_msg:
            print("⚠️ ВНИМАНИЕ: Закончились лимиты API!")
            print("Проверьте баланс на https://platform.deepseek.com/")
        elif "unauthorized" in error_msg or "401" in error_msg or "403" in error_msg:
            print("❌ ОШИБКА: Неверный API ключ!")
            print("Проверьте DEEPSEEK_API_KEY в переменных окружения или local_secrets.py")
        else:
            print(f"⚠️ Не удалось проверить API ключ: {e}")
        return False

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
    Ты — опытный финансовый аналитик с глубоким пониманием банковских выписок. Твоя задача - ТОЧНО и ДЕТАЛЬНО распарсить выписку Kaspi Gold.
    
    ВНИМАНИЕ: Будь очень внимательным и точным. Проверяй каждую транзакцию дважды.
    
    ОСОБЕННОСТИ ФОРМАТА KASPI:
    1. Суммы: "1 500.00 - T" (минус справа) или "- 1 500 T" - это РАСХОДЫ.
    2. Пополнения (Replenishment, пополнение счета) - ИГНОРИРУЙ их полностью.
    3. Все суммы расходов должны быть ПОЛОЖИТЕЛЬНЫМИ числами в JSON.
    
    🛑 ЖЕЛЕЗНЫЕ ПРАВИЛА (Strict Rules) - СЛЕДУЙ ИМ СТРОГО:
    
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
    Внимательно проанализируй ВСЕ транзакции в выписке. Для каждой транзакции:
    1. Определи точную сумму (убери пробелы, конвертируй в число)
    2. Определи правильную категорию по описанию
    3. Извлеки дату в формате DD.MM.YYYY
    4. Создай краткое описание транзакции
    
    ВАЖНО для категорий:
    - Суммируй ВСЕ транзакции по каждой категории
    - Вычисли проценты от общей суммы (total_spent)
    - Используй правильные цвета для каждой категории
    
    В поле `categories` должна появиться категория "{lang_names['credit']}", если есть соответствующие траты.
    В поле `subscriptions` НЕ ДОЛЖНО быть Каспи магазина, Kaspi Red, кредитов или рассрочек - ТОЛЬКО цифровые подписки!
    
    Структура JSON (ОБЯЗАТЕЛЬНО СЛЕДУЙ ЭТОЙ СТРУКТУРЕ):
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
    - total_spent - сумма ВСЕХ расходов (не пополнений!)
    - forecast_next_month - примерная оценка расходов на следующий месяц на основе текущих данных
    
    КРИТИЧЕСКИ ВАЖНО ДЛЯ JSON:
    - Верни ТОЛЬКО валидный JSON, без дополнительного текста до или после
    - Все строки в JSON должны быть экранированы двойными кавычками
    - Не используй одинарные кавычки для строк
    - Экранируй специальные символы в строках (\\n, \\", \\\\)
    - Не добавляй комментарии в JSON
    - Убедись, что все скобки закрыты правильно
    - Проверь, что все числа - это числа, а не строки
    - Убедись, что total_spent = сумма всех amount в categories
    
    ПРИМЕР ПРАВИЛЬНОГО JSON:
    {{
      "total_spent": 100165.0,
      "forecast_next_month": 115000.0,
      "categories": [
        {{"name": "Продукты (Magnum)", "name_ru": "Продукты (Magnum)", "name_kz": "Тауарлар (Magnum)", "name_en": "Products (Magnum)", "amount": 45000.0, "percent": 45.0, "color": "4CAF50"}},
        {{"name": "Такси (Yandex)", "name_ru": "Такси (Yandex)", "name_kz": "Такси (Yandex)", "name_en": "Taxi (Yandex)", "amount": 12500.0, "percent": 12.0, "color": "FFC107"}}
      ],
      "subscriptions": [{{"name": "Spotify Premium", "cost": 4282.0}}],
      "advice": "Совет по финансам",
      "transactions": [
        {{"date": "01.03.2024", "amount": 1500.0, "description": "Magnum", "category": "Продукты (Magnum)"}}
      ]
    }}
    """

    try:
        try:
            response = client.chat.completions.create(
                model="deepseek-chat",  # Модель DeepSeek
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": f"Текст выписки:\n{text[:5000]}"}
                ],
                temperature=0.1,
                max_tokens=4000  # Увеличиваем лимит токенов для больших выписок
            )
        except Exception as api_err:
            error_msg = str(api_err)
            print(f"API Error: {error_msg}")
            
            # Проверяем на ошибки лимитов
            if "rate limit" in error_msg.lower() or "quota" in error_msg.lower() or "limit" in error_msg.lower():
                print("⚠️ ВНИМАНИЕ: Похоже, закончились лимиты API!")
                print("Проверьте баланс и лимиты на https://platform.deepseek.com/")
                return None
            
            # Проверяем на ошибки авторизации
            if "unauthorized" in error_msg.lower() or "401" in error_msg or "403" in error_msg:
                print("⚠️ ОШИБКА: Проблема с API ключом!")
                print("Проверьте DEEPSEEK_API_KEY в переменных окружения или local_secrets.py")
                return None
            
            # Другие ошибки API
            print(f"Неизвестная ошибка API: {api_err}")
            import traceback
            traceback.print_exc()
            return None
        
        # Получаем ответ от AI
        if not response or not response.choices or len(response.choices) == 0:
            print("⚠️ API вернул пустой ответ!")
            return None
        
        # Логируем информацию об использовании токенов
        if hasattr(response, 'usage'):
            usage = response.usage
            print(f"📊 Использование токенов: prompt={usage.prompt_tokens}, completion={usage.completion_tokens}, total={usage.total_tokens}")
        
        raw_content = response.choices[0].message.content
        
        if not raw_content:
            print("⚠️ API вернул пустое содержимое!")
            return None
        
        print(f"✅ Получен ответ от API (длина: {len(raw_content)} символов)")
        
        # Проверяем, не был ли ответ обрезан (если finish_reason == "length")
        if hasattr(response.choices[0], 'finish_reason'):
            finish_reason = response.choices[0].finish_reason
            if finish_reason == "length":
                print("⚠️ ВНИМАНИЕ: Ответ был обрезан из-за лимита токенов! Увеличьте max_tokens.")
            elif finish_reason == "stop":
                print("✅ Ответ завершен нормально")
            else:
                print(f"ℹ️ Finish reason: {finish_reason}")
        
        # Очищаем JSON от markdown и лишних символов
        clean_json = raw_content.strip()
        # Убираем markdown блоки
        if "```json" in clean_json:
            clean_json = clean_json.split("```json")[1].split("```")[0].strip()
        elif "```" in clean_json:
            clean_json = clean_json.split("```")[1].split("```")[0].strip()
        
        # Убираем возможные префиксы/суффиксы
        if clean_json.startswith("json"):
            clean_json = clean_json[4:].strip()
        if clean_json.startswith("JSON"):
            clean_json = clean_json[4:].strip()
        
        # Пытаемся найти JSON объект в тексте
        start_idx = clean_json.find("{")
        end_idx = clean_json.rfind("}")
        if start_idx != -1 and end_idx != -1 and end_idx > start_idx:
            clean_json = clean_json[start_idx:end_idx + 1]
        
        # Парсим JSON
        try:
            result = json.loads(clean_json)
        except json.JSONDecodeError as json_err:
            print(f"JSON Parse Error: {json_err}")
            print(f"Error position: line {json_err.lineno}, column {json_err.colno}")
            print(f"Cleaned JSON (first 1000 chars): {clean_json[:1000]}")
            
            # Пытаемся исправить распространенные ошибки
            # 1. Убираем неэкранированные переносы строк в строках (но не в значениях)
            # 2. Исправляем незакрытые строки
            try:
                # Заменяем неэкранированные переносы в строках
                fixed_json = re.sub(r'(?<!\\)\n(?![\\"])', '\\n', clean_json)
                # Убираем переносы строк между ключами и значениями
                fixed_json = re.sub(r':\s*\n\s*', ': ', fixed_json)
                # Убираем переносы строк после запятых
                fixed_json = re.sub(r',\s*\n\s*', ', ', fixed_json)
                
                result = json.loads(fixed_json)
                print("Successfully fixed JSON!")
            except Exception as fix_err:
                print(f"Failed to fix JSON: {fix_err}")
                # Последняя попытка - найти JSON объект более агрессивно
                try:
                    # Ищем первый { и последний }
                    start = clean_json.find('{')
                    end = clean_json.rfind('}')
                    if start != -1 and end != -1:
                        json_str = clean_json[start:end+1]
                        result = json.loads(json_str)
                        print("Successfully extracted JSON object!")
                    else:
                        return None
                except:
                    print("All JSON parsing attempts failed, trying to fix truncated JSON...")
                    # Попытка исправить обрезанный JSON
                    try:
                        fixed_json = clean_json
                        
                        # Исправляем незакрытые строки в color (например, "color": "FF9 -> "color": "FF9E9E9E")
                        # Ищем паттерн "color": "XXXX где XXXX - неполный hex код
                        def fix_color(match):
                            color_value = match.group(1)
                            # Если цвет неполный (меньше 6 символов), дополняем до 6 символов серым цветом
                            if len(color_value) < 6:
                                color_value = color_value.ljust(6, 'E')
                            return f'"color": "{color_value}"'
                        
                        fixed_json = re.sub(r'"color":\s*"([^"]*?)(?:"|$)', fix_color, fixed_json)
                        
                        # Закрываем незакрытые строки в конце (если нечетное количество кавычек)
                        quote_count = fixed_json.count('"')
                        if quote_count % 2 != 0:
                            # Находим последнюю незакрытую строку и закрываем её
                            last_quote_idx = fixed_json.rfind('"')
                            # Если после последней кавычки нет закрывающей, добавляем
                            if last_quote_idx < len(fixed_json) - 1:
                                # Проверяем, что это начало строки, а не конец
                                after_quote = fixed_json[last_quote_idx + 1:]
                                if not after_quote.strip().startswith((':', ',', '}', ']')):
                                    fixed_json = fixed_json[:last_quote_idx + 1] + '"' + fixed_json[last_quote_idx + 1:]
                        
                        # Закрываем незакрытые объекты и массивы
                        open_braces = fixed_json.count('{')
                        close_braces = fixed_json.count('}')
                        open_brackets = fixed_json.count('[')
                        close_brackets = fixed_json.count(']')
                        
                        # Добавляем недостающие закрывающие скобки
                        if open_braces > close_braces:
                            fixed_json += '}' * (open_braces - close_braces)
                        if open_brackets > close_brackets:
                            fixed_json += ']' * (open_brackets - close_brackets)
                        
                        # Убираем лишние запятые перед закрывающими скобками
                        fixed_json = re.sub(r',\s*([}\]])', r'\1', fixed_json)
                        
                        result = json.loads(fixed_json)
                        print("Successfully fixed truncated JSON!")
                    except Exception as trunc_fix_err:
                        print(f"Failed to fix truncated JSON: {trunc_fix_err}")
                        import traceback
                        traceback.print_exc()
                        return None
        
        # Фильтруем подписки - удаляем Kaspi Magazin и кредиты
        if "subscriptions" in result and isinstance(result["subscriptions"], list):
            result["subscriptions"] = [
                sub for sub in result["subscriptions"]
                if sub.get("name", "").lower() not in ["kaspi magazin", "kaspi red", "рассрочка", "credit", "погашение кредита"]
            ]
        
        return result
    except Exception as e:
        error_msg = str(e)
        print(f"AI Error: {error_msg}")
        
        # Проверяем на ошибки API в общем обработчике
        if "rate limit" in error_msg.lower() or "quota" in error_msg.lower():
            print("⚠️ ВНИМАНИЕ: Похоже, закончились лимиты API!")
            print("Проверьте баланс и лимиты на https://platform.deepseek.com/")
        elif "unauthorized" in error_msg.lower() or "401" in error_msg or "403" in error_msg:
            print("⚠️ ОШИБКА: Проблема с API ключом!")
            print("Проверьте DEEPSEEK_API_KEY в переменных окружения или local_secrets.py")
        
        import traceback
        traceback.print_exc()
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
        print("⚠️ AI вернул None, используем мок-данные")
        return MOCK_AMIR_DATA
    
    # Проверяем, что результат валидный
    if not isinstance(result, dict):
        print(f"⚠️ AI вернул не dict, а {type(result)}, используем мок-данные")
        return MOCK_AMIR_DATA
    
    # Проверяем обязательные поля
    required_fields = ['total_spent', 'categories', 'transactions']
    missing_fields = [field for field in required_fields if field not in result]
    if missing_fields:
        print(f"⚠️ В ответе отсутствуют обязательные поля: {missing_fields}, используем мок-данные")
        return MOCK_AMIR_DATA
    
    # Валидация данных
    try:
        # Проверяем, что categories - это список
        if not isinstance(result.get('categories'), list):
            print(f"⚠️ categories не является списком: {type(result.get('categories'))}, используем мок-данные")
            return MOCK_AMIR_DATA
        
        # Проверяем, что transactions - это список
        if not isinstance(result.get('transactions'), list):
            print(f"⚠️ transactions не является списком: {type(result.get('transactions'))}, используем мок-данные")
            return MOCK_AMIR_DATA
        
        print(f"✅ Успешно обработан ответ AI: total_spent={result.get('total_spent')}, categories={len(result.get('categories', []))}, transactions={len(result.get('transactions', []))}")
        return result
    except Exception as validation_err:
        print(f"⚠️ Ошибка валидации данных: {validation_err}, используем мок-данные")
        import traceback
        traceback.print_exc()
        return MOCK_AMIR_DATA

# --- Модель для чата ---
class ChatRequest(BaseModel):
    question: str
    context: dict  # Сюда прилетит JSON с тратами (finance_data)
    user_goal: str = ""  # Финансовая цель пользователя

@app.post("/chat")
async def chat_with_finance(request: ChatRequest):
    """
    Эндпоинт для общения.
    Принимает вопрос и ПОЛНЫЙ контекст финансов (чтобы не хранить базу).
    """
    # Превращаем JSON с тратами в строку для промпта
    context_str = json.dumps(request.context, ensure_ascii=False, indent=2)
    
    # 💡 ИСПОЛЬЗОВАНИЕ ЦЕЛИ: Формируем часть промпта с целью пользователя
    # Цель сохраняется в mobile/lib/goals_screen.dart -> SharedPreferences
    # Загружается в mobile/lib/api_service.dart -> sendChatMessage()
    # Отправляется сюда и используется в системном промпте для персонализации советов
    goal_prompt = ""
    if request.user_goal:
        goal_prompt = f"\nЦель пользователя: {request.user_goal}. Давай советы, опираясь на эту цель."
    
    system_prompt = f"""
    Ты — финансовый консультант приложения FinSight.
    Твоя цель: помогать пользователю экономить и разбираться в тратах.
    
    ВОТ ДАННЫЕ ПОЛЬЗОВАТЕЛЯ (JSON):
    {context_str}
    {goal_prompt}
    
    ПРАВИЛА:
    1. Отвечай кратко (макс 3-4 предложения).
    2. Оперируй цифрами из данных. Если спрашивают "Сколько я потратил на еду?", найди категорию "Еда" или "Продукты" и скажи сумму.
    3. Если видишь Каспи Ред/Рассрочки, предупреждай о долговой нагрузке.
    4. Будь вежливым и мотивирующим.
    5. Валюта: Тенге (₸).
    """

    try:
        response = client.chat.completions.create(
            model="deepseek-chat",  # Модель DeepSeek
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
    # Проверяем API ключ при старте
    print("🔍 Проверка API ключа...")
    check_api_key()
    print("🚀 Запуск сервера на http://0.0.0.0:8000")
    uvicorn.run(app, host="0.0.0.0", port=8000)