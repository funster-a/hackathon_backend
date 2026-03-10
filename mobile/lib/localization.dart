import 'package:flutter/material.dart';

enum Language { ru, kz, en }

class AppStrings {
  // 🔥 Магия реактивности: слушаем изменения языка
  static final ValueNotifier<Language> languageNotifier = ValueNotifier(
    Language.ru,
  );

  static Language get currentLanguage => languageNotifier.value;

  static void setLanguage(Language lang) {
    languageNotifier.value = lang;
  }

  // СЛОВАРЬ ПЕРЕВОДОВ
  static final Map<String, Map<Language, String>> _data = {
    // --- ГЛАВНЫЙ ЭКРАН ---
    'total_spent': {
      Language.ru: 'Необходимый бюджет',
      Language.kz: 'Қажетті бюджет',
      Language.en: 'Required Budget',
    },
    'forecast': {
      Language.ru: 'Burn Rate',
      Language.kz: 'Burn Rate',
      Language.en: 'Burn Rate',
    },
    'categories_title': {
      Language.ru: 'Распределение бюджета',
      Language.kz: 'Бюджетті бөлу',
      Language.en: 'Budget Distribution',
    },
    'advice_title': {
      Language.ru: 'Совет AI',
      Language.kz: 'AI Кеңесі',
      Language.en: 'AI Advice',
    },
    'subs_title': {
      Language.ru: 'Команда MVP',
      Language.kz: 'MVP командасы',
      Language.en: 'MVP Team',
    },
    'upload_btn': {
      Language.ru: 'Рассчитать другую идею',
      Language.kz: 'Басқа идеяны есептеу',
      Language.en: 'Calculate another idea',
    },
    'upload_screen_title': {
      Language.ru: 'Опишите идею стартапа',
      Language.kz: 'Стартап идеяңызды сипаттаңыз',
      Language.en: 'Describe your startup idea',
    },
    'upload_screen_btn': {
      Language.ru: 'Рассчитать смету',
      Language.kz: 'Сметаны есептеу',
      Language.en: 'Calculate Plan',
    },

    // --- ЧАТ ---
    'chat_title': {
      Language.ru: 'Ментор AI',
      Language.kz: 'AI Тәлімгер',
      Language.en: 'AI Mentor',
    },
    'chat_hint': {
      Language.ru: 'Спроси о стартапе...',
      Language.kz: 'Стартап туралы сұраңыз...',
      Language.en: 'Ask about the startup...',
    },
    'chat_empty_message': {
      Language.ru: 'Рассчитайте идею, чтобы начать чат',
      Language.kz: 'Чатты бастау үшін идеяны есептеңіз',
      Language.en: 'Calculate an idea to start chatting',
    },

    // --- ПРОФИЛЬ ---
    'profile_title': {
      Language.ru: 'Профиль',
      Language.kz: 'Профиль',
      Language.en: 'Profile',
    },
    'profile_guest': {
      Language.ru: 'Фаундер',
      Language.kz: 'Негізін қалаушы (Фаундер)',
      Language.en: 'Founder',
    },
    'settings_lang': {
      Language.ru: 'Язык приложения',
      Language.kz: 'Қолданба тілі',
      Language.en: 'App Language',
    },
    'logout': {
      Language.ru: 'Выйти из аккаунта',
      Language.kz: 'Шығу',
      Language.en: 'Log Out',
    },
    'status_free': {
      Language.ru: 'Статус: Базовый',
      Language.kz: 'Статус: Базалық',
      Language.en: 'Status: Basic',
    },
    'status_premium': {
      Language.ru: 'Статус: Единорог 🦄',
      Language.kz: 'Статус: Unicorn 🦄',
      Language.en: 'Status: Unicorn 🦄',
    },
    'limit_requests': {
      Language.ru: 'Лимит: 5 расчетов',
      Language.kz: 'Шектеу: 5 есептеу',
      Language.en: 'Limit: 5 calculations',
    },
    'remaining': {
      Language.ru: 'Осталось',
      Language.kz: 'Қалды',
      Language.en: 'Remaining',
    },
    'unlimited': {
      Language.ru: 'Безлимит',
      Language.kz: 'Шексіз',
      Language.en: 'Unlimited',
    },
    'upgrade': {
      Language.ru: 'Прокачать',
      Language.kz: 'Жақсарту',
      Language.en: 'Upgrade',
    },

    // --- WELCOME SCREEN ---
    'welcome_title': {
      Language.ru: 'Startup Analyzer',
      Language.kz: 'Startup Analyzer',
      Language.en: 'Startup Analyzer',
    },
    'welcome_subtitle': {
      Language.ru: 'Твой личный AI-эдвайзер',
      Language.kz: 'Сенің жеке AI-кеңесшің',
      Language.en: 'Your personal AI advisor',
    },
    'welcome_feature1': {
      Language.ru: 'Опиши идею стартапа',
      Language.kz: 'Стартап идеяңды сипатта',
      Language.en: 'Describe your startup idea',
    },
    'welcome_feature2': {
      Language.ru: 'Получи смету и план команды',
      Language.kz: 'Смета мен команда жоспарын ал',
      Language.en: 'Get a budget and team plan',
    },
    'welcome_feature3': {
      Language.ru: 'Общайся с AI о стратегии',
      Language.kz: 'AI-мен стратегия туралы сөйлес',
      Language.en: 'Discuss strategy with AI',
    },
    'welcome_button': {
      Language.ru: 'Создать стартап',
      Language.kz: 'Стартап құру',
      Language.en: 'Create Startup',
    },

    // --- REGISTRATION SCREEN ---
    'registration_title': {
      Language.ru: 'Как тебя зовут, фаундер?',
      Language.kz: 'Атың кім, фаундер?',
      Language.en: 'What\'s your name, founder?',
    },
    'registration_subtitle': {
      Language.ru: 'Давай создадим твой первый единорог',
      Language.kz: 'Алғашқы unicorn-ды бірге жасайық',
      Language.en: 'Let\'s build your first unicorn',
    },
    'registration_name_hint': {
      Language.ru: 'Введите ваше имя',
      Language.kz: 'Атыңызды енгізіңіз',
      Language.en: 'Enter your name',
    },
    'registration_button': {
      Language.ru: 'Начать',
      Language.kz: 'Бастау',
      Language.en: 'Start',
    },
    'registration_name_required': {
      Language.ru: 'Пожалуйста, введите ваше имя',
      Language.kz: 'Атыңызды енгізіңіз',
      Language.en: 'Please enter your name',
    },

    // --- PREMIUM SCREEN ---
    'premium_title': {
      Language.ru: 'Founder PRO',
      Language.kz: 'Founder PRO',
      Language.en: 'Founder PRO',
    },
    'premium_subtitle': {
      Language.ru: 'Разблокируй полную мощь AI',
      Language.kz: 'AI-дың толық қуатын ашыңыз',
      Language.en: 'Unlock the full power of AI',
    },
    'premium_feature1': {
      Language.ru: 'Безлимитные расчеты идей',
      Language.kz: 'Шексіз идеяларды есептеу',
      Language.en: 'Unlimited idea calculations',
    },
    'premium_feature2': {
      Language.ru: 'Глубокий анализ бизнес-модели',
      Language.kz: 'Бизнес-модельді терең талдау',
      Language.en: 'Deep business model analysis',
    },
    'premium_feature3': {
      Language.ru: 'Экспорт pitch deck (PDF/PPT)',
      Language.kz: 'Pitch deck экспорты (PDF/PPT)',
      Language.en: 'Export pitch deck (PDF/PPT)',
    },
    'premium_feature4': {
      Language.ru: 'Доступ для кофаундеров',
      Language.kz: 'Кофаундерлерге қол жетімділік',
      Language.en: 'Co-founder access',
    },
    'premium_price': {
      Language.ru: '990 ₸ / месяц',
      Language.kz: '990 ₸ / ай',
      Language.en: '990 ₸ / month',
    },
    'premium_trial': {
      Language.ru: 'Первые 7 дней бесплатно',
      Language.kz: 'Алғашқы 7 күн тегін',
      Language.en: 'First 7 days free',
    },
    'premium_button': {
      Language.ru: 'Оформить подписку',
      Language.kz: 'Жазылымды рәсімдеу',
      Language.en: 'Subscribe',
    },
    'premium_demo_success': {
      Language.ru: 'Демо режим: Покупка успешна!',
      Language.kz: 'Демо режим: Сатып алу сәтті!',
      Language.en: 'Demo mode: Purchase successful!',
    },

    // --- CHAT SCREEN ---
    'chat_welcome_message': {
      Language.ru:
          'Привет! Я твой AI-ментор по стартапам. Я помогу рассчитать бюджет, подобрать команду и составить план для MVP. Опиши свою идею, и мы начнем!',
      Language.kz:
          'Сәлем! Мен сенің стартаптар бойынша AI-тәлімгеріңмін. Бюджетті есептеуге, MVP командасын жинауға көмектесемін. Өз идеяңды сипатта, бастайық!',
      Language.en:
          'Hello! I\'m your startup AI mentor. I will help calculate your budget, select a team, and create an MVP plan. Describe your idea and let\'s start!',
    },
    'chat_typing': {
      Language.ru: 'AI думает над стратегией...',
      Language.kz: 'AI стратегияны ойластырып жатыр...',
      Language.en: 'AI is thinking about strategy...',
    },
    'chat_suggestion1': {
      Language.ru: '📉 Как сэкономить на серверах?',
      Language.kz: '📉 Серверлерден қалай үнемдеуге болады?',
      Language.en: '📉 How to save on servers?',
    },
    'chat_suggestion2': {
      Language.ru: '🏆 Какие специалисты нужны?',
      Language.kz: '🏆 Қандай мамандар қажет?',
      Language.en: '🏆 What specialists do I need?',
    },
    'chat_suggestion3': {
      Language.ru: '🔮 Как найти первых клиентов?',
      Language.kz: '🔮 Алғашқы клиенттерді қалай табамын?',
      Language.en: '🔮 How to find first clients?',
    },
    'chat_suggestion4': {
      Language.ru: '🍔 Какой маркетинговый бюджет нужен?',
      Language.kz: '🍔 Маркетингке қанша бюджет керек?',
      Language.en: '🍔 What marketing budget is needed?',
    },
    'chat_suggestion5': {
      Language.ru: '🚕 Как уменьшить Burn Rate?',
      Language.kz: '🚕 Burn Rate-ті қалай азайтамыз?',
      Language.en: '🚕 How to reduce Burn Rate?',
    },
    'chat_suggestion6': {
      Language.ru: '💳 Как привлечь инвестора?',
      Language.kz: '💳 Инвесторды қалай тартамын?',
      Language.en: '💳 How to attract investors?',
    },
    'chat_error': {
      Language.ru: 'Ошибка связи с сервером 😔',
      Language.kz: 'Сервермен байланыс қатесі 😔',
      Language.en: 'Server connection error 😔',
    },

    // --- MAIN SCREEN ---
    'ai_chat_button': {
      Language.ru: 'Чат с Ментором',
      Language.kz: 'Тәлімгермен Чат',
      Language.en: 'Chat with Mentor',
    },
    'app_title': {
      Language.ru: 'Startup Analyzer',
      Language.kz: 'Startup Analyzer',
      Language.en: 'Startup Analyzer',
    },
    'dashboard_title': {
      Language.ru: 'Смета',
      Language.kz: 'Смета',
      Language.en: 'Estimation',
    },

    // --- LIMIT DIALOGS ---
    'limit_exceeded_title': {
      Language.ru: 'Лимит расчетов исчерпан',
      Language.kz: 'Есептеу шегі аяқталды',
      Language.en: 'Calculation Limit Exceeded',
    },
    'limit_exceeded_message': {
      Language.ru:
          'Вы использовали все бесплатные расчеты идей. Перейдите на PRO для безлимитного доступа.',
      Language.kz:
          'Сіз барлық тегін идея есептеулерін пайдаландыңыз. Шексіз қол жетімділік үшін PRO-ға өтіңіз.',
      Language.en:
          'You have used all free idea calculations. Upgrade to PRO for unlimited access.',
    },
    'go_to_premium': {
      Language.ru: 'Перейти на PRO',
      Language.kz: 'PRO-ға өту',
      Language.en: 'Go to PRO',
    },
    'cancel': {
      Language.ru: 'Отмена',
      Language.kz: 'Болдырмау',
      Language.en: 'Cancel',
    },
    'premium_activated': {
      Language.ru: 'Вы перешли на PRO!',
      Language.kz: 'Сіз PRO-ға өттіңіз!',
      Language.en: 'You upgraded to PRO!',
    },

    // --- PERIOD FILTER (Может не использоваться, но оставим для совместимости) ---
    'period_week': {
      Language.ru: 'MVP (3 мес)',
      Language.kz: 'MVP (3 ай)',
      Language.en: 'MVP (3 mo)',
    },
    'period_month': {
      Language.ru: '1 Год',
      Language.kz: '1 Жыл',
      Language.en: '1 Year',
    },
    'period_all': {
      Language.ru: 'Все время',
      Language.kz: 'Барлық уақыт',
      Language.en: 'All time',
    },
    'recent_transactions': {
      Language.ru: 'Последние изменения',
      Language.kz: 'Соңғы өзгерістер',
      Language.en: 'Recent changes',
    },

    // --- GOALS SCREEN ---
    'goals_title': {
      Language.ru: 'Бизнес Цели',
      Language.kz: 'Бизнес Мақсаттар',
      Language.en: 'Business Goals',
    },
    'goals_subtitle': {
      Language.ru:
          'Укажите цель вашего стартапа и начальный бюджет для персонализации',
      Language.kz:
          'Жекелендіру үшін стартаптың мақсатын және бастапқы бюджетті көрсетіңіз',
      Language.en:
          'Specify your startup goal and initial budget for personalization',
    },
    'goals_goal_label': {
      Language.ru: 'Цель стартапа',
      Language.kz: 'Стартап мақсаты',
      Language.en: 'Startup Goal',
    },
    'goals_goal_hint': {
      Language.ru: 'Например: Запустить MVP за 3 месяца',
      Language.kz: 'Мысалы: MVP-ді 3 айда іске қосу',
      Language.en: 'For example: Launch MVP in 3 months',
    },
    'goals_income_label': {
      Language.ru: 'Доступный начальный капитал',
      Language.kz: 'Қолжетімді бастапқы капитал',
      Language.en: 'Available Initial Capital',
    },
    'goals_income_hint': {
      Language.ru: 'Выберите диапазон инвестиций',
      Language.kz: 'Инвестиция диапазонын таңдаңыз',
      Language.en: 'Select investment range',
    },
    'goals_save_button': {
      Language.ru: 'Сохранить план',
      Language.kz: 'Жоспарды сақтау',
      Language.en: 'Save Plan',
    },
    'goals_saved': {
      Language.ru: 'Цель успешно сохранена!',
      Language.kz: 'Мақсат сәтті сақталды!',
      Language.en: 'Goal saved successfully!',
    },
    'goals_error_empty': {
      Language.ru: 'Пожалуйста, укажите цель стартапа',
      Language.kz: 'Стартап мақсатын көрсетіңіз',
      Language.en: 'Please specify your startup goal',
    },
    'goals_error_save': {
      Language.ru: 'Ошибка при сохранении',
      Language.kz: 'Сақтау кезінде қате',
      Language.en: 'Error saving',
    },
    'goals_menu_item': {
      Language.ru: 'Цели стартапа',
      Language.kz: 'Стартап мақсаттары',
      Language.en: 'Startup Goals',
    },
    'goals_saved_list_title': {
      Language.ru: 'Сохраненные планы',
      Language.kz: 'Сақталған жоспарлар',
      Language.en: 'Saved Plans',
    },
    'goals_income_option1': {
      Language.ru: 'До 1 000 000 ₸',
      Language.kz: '1 000 000 ₸ дейін',
      Language.en: 'Up to 1,000,000 ₸',
    },
    'goals_income_option2': {
      Language.ru: '1 000 000 - 5 000 000 ₸',
      Language.kz: '1 000 000 - 5 000 000 ₸',
      Language.en: '1,000,000 - 5,000,000 ₸',
    },
    'goals_income_option3': {
      Language.ru: '5 000 000 - 10 000 000 ₸',
      Language.kz: '5 000 000 - 10 000 000 ₸',
      Language.en: '5,000,000 - 10,000,000 ₸',
    },
    'goals_income_option4': {
      Language.ru: '10 000 000 - 50 000 000 ₸',
      Language.kz: '10 000 000 - 50 000 000 ₸',
      Language.en: '10,000,000 - 50,000,000 ₸',
    },
    'goals_income_option5': {
      Language.ru: '50 000 000 - 100 000 000 ₸',
      Language.kz: '50 000 000 - 100 000 000 ₸',
      Language.en: '50,000,000 - 100,000,000 ₸',
    },
    'goals_income_option6': {
      Language.ru: 'Свыше 100 000 000 ₸',
      Language.kz: '100 000 000 ₸ астам',
      Language.en: 'Over 100,000,000 ₸',
    },

    // --- PIN SCREEN ---
    'pin_setup_title': {
      Language.ru: 'Установите ПИН-код',
      Language.kz: 'PIN-кодты орнатыңыз',
      Language.en: 'Set PIN Code',
    },
    'pin_setup_subtitle': {
      Language.ru: 'Введите 4-значный ПИН-код',
      Language.kz: '4 таңбалы PIN-кодты енгізіңіз',
      Language.en: 'Enter 4-digit PIN code',
    },
    'pin_confirm_title': {
      Language.ru: 'Подтвердите ПИН-код',
      Language.kz: 'PIN-кодты растаңыз',
      Language.en: 'Confirm PIN Code',
    },
    'pin_confirm_subtitle': {
      Language.ru: 'Повторите ПИН-код для подтверждения',
      Language.kz: 'Растау үшін PIN-кодты қайталаңыз',
      Language.en: 'Repeat PIN code to confirm',
    },
    'pin_verify_title': {
      Language.ru: 'Введите ПИН-код',
      Language.kz: 'PIN-кодты енгізіңіз',
      Language.en: 'Enter PIN Code',
    },
    'pin_verify_subtitle': {
      Language.ru: 'Для доступа к проекту',
      Language.kz: 'Жобаға кіру үшін',
      Language.en: 'To access the project',
    },
    'pin_enter_old_title': {
      Language.ru: 'Введите текущий ПИН-код',
      Language.kz: 'Ағымдағы PIN-кодты енгізіңіз',
      Language.en: 'Enter Current PIN',
    },
    'pin_enter_old_subtitle': {
      Language.ru: 'Для изменения ПИН-кода',
      Language.kz: 'PIN-кодты өзгерту үшін',
      Language.en: 'To change PIN code',
    },
    'pin_error_wrong': {
      Language.ru: 'Неверный ПИН-код',
      Language.kz: 'Қате PIN-код',
      Language.en: 'Wrong PIN code',
    },
    'pin_error_mismatch': {
      Language.ru: 'ПИН-коды не совпадают',
      Language.kz: 'PIN-кодтар сәйкес келмейді',
      Language.en: 'PIN codes do not match',
    },
    'pin_menu_setup': {
      Language.ru: 'Установить ПИН-код',
      Language.kz: 'PIN-кодты орнату',
      Language.en: 'Set PIN Code',
    },
    'pin_menu_change': {
      Language.ru: 'Изменить ПИН-код',
      Language.kz: 'PIN-кодты өзгерту',
      Language.en: 'Change PIN Code',
    },
    'pin_menu_remove': {
      Language.ru: 'Удалить ПИН-код',
      Language.kz: 'PIN-кодты жою',
      Language.en: 'Remove PIN Code',
    },

    // --- АВАТАР ---
    'avatar_menu_item': {
      Language.ru: 'Сменить аватар',
      Language.kz: 'Аватарды өзгерту',
      Language.en: 'Change Avatar',
    },
    'avatar_dialog_title': {
      Language.ru: 'Выберите аватар',
      Language.kz: 'Аватарды таңдаңыз',
      Language.en: 'Choose Avatar',
    },
    'avatar_from_gallery': {
      Language.ru: 'Моё фото',
      Language.kz: 'Менің фотосуретым',
      Language.en: 'My Photo',
    },
    'avatar_defaults': {
      Language.ru: 'Или выберите из коллекции',
      Language.kz: 'Немесе коллекциядан таңдаңыз',
      Language.en: 'Or choose from collection',
    },
    'avatar_uploaded': {
      Language.ru: 'Загруженные фото',
      Language.kz: 'Жүктелген фотосуреттер',
      Language.en: 'Uploaded photos',
    },

    // --- SKIP / AUTH ---
    'skip': {
      Language.ru: 'Пропустить',
      Language.kz: 'Өткізіп жіберу',
      Language.en: 'Skip',
    },
    'auth_title': {
      Language.ru: 'Вход в систему',
      Language.kz: 'Жүйеге кіру',
      Language.en: 'Sign In',
    },
    'auth_subtitle': {
      Language.ru: 'Введите ПИН-код для доступа',
      Language.kz: 'Қол жеткізу үшін PIN-кодты енгізіңіз',
      Language.en: 'Enter PIN to access',
    },
    'auth_register': {
      Language.ru: 'Регистрация',
      Language.kz: 'Тіркелу',
      Language.en: 'Register',
    },
    'auth_login': {
      Language.ru: 'Войти',
      Language.kz: 'Кіру',
      Language.en: 'Sign In',
    },
    'auth_no_account': {
      Language.ru: 'Нет аккаунта?',
      Language.kz: 'Аккаунт жоқ па?',
      Language.en: 'No account?',
    },
    'auth_register_new': {
      Language.ru: 'Создать новый аккаунт',
      Language.kz: 'Жаңа аккаунт құру',
      Language.en: 'Create new account',
    },
    'auth_has_account': {
      Language.ru: 'Уже есть аккаунт?',
      Language.kz: 'Аккаунт бар ма?',
      Language.en: 'Already have account?',
    },
    'auth_pin_not_set': {
      Language.ru: 'Установите ПИН-код при регистрации',
      Language.kz: 'Тіркелу кезінде PIN-кодты орнатыңыз',
      Language.en: 'Set PIN code during registration',
    },
  };

  static String get(String key) {
    return _data[key]?[currentLanguage] ?? key;
  }

  // Получить код языка для API (ru, kz, en)
  static String get languageCode {
    switch (currentLanguage) {
      case Language.ru:
        return 'ru';
      case Language.kz:
        return 'kz';
      case Language.en:
        return 'en';
    }
  }
}
