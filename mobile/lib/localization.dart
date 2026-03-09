import 'package:flutter/material.dart';

enum Language { ru, kz, en }

class AppStrings {
  // 🔥 Магия реактивности: слушаем изменения языка
  static final ValueNotifier<Language> languageNotifier = ValueNotifier(Language.ru);

  static Language get currentLanguage => languageNotifier.value;

  static void setLanguage(Language lang) {
    languageNotifier.value = lang;
  }

  // СЛОВАРЬ ПЕРЕВОДОВ
  static final Map<String, Map<Language, String>> _data = {
    // --- ГЛАВНЫЙ ЭКРАН ---
    'total_spent': {
      Language.ru: 'Всего потрачено',
      Language.kz: 'Жалпы шығын',
      Language.en: 'Total Spent',
    },
    'forecast': {
      Language.ru: 'Прогноз',
      Language.kz: 'Болжам',
      Language.en: 'Forecast',
    },
    'categories_title': {
      Language.ru: 'Анализ категорий',
      Language.kz: 'Санаттар талдауы',
      Language.en: 'Categories Analysis',
    },
    'advice_title': {
      Language.ru: 'Совет AI',
      Language.kz: 'AI Кеңесі',
      Language.en: 'AI Advice',
    },
    'subs_title': {
      Language.ru: 'Подписки',
      Language.kz: 'Жазылымдар',
      Language.en: 'Subscriptions',
    },
    'upload_btn': {
      Language.ru: 'Загрузить другой файл',
      Language.kz: 'Басқа файлды жүктеу',
      Language.en: 'Upload another file',
    },
    'upload_screen_title': {
      Language.ru: 'Загрузите выписку Kaspi (PDF)',
      Language.kz: 'Kaspi үзіндісін жүктеңіз (PDF)',
      Language.en: 'Upload Kaspi Statement (PDF)',
    },
    'upload_screen_btn': {
      Language.ru: 'Выбрать файл',
      Language.kz: 'Файлды таңдау',
      Language.en: 'Select File',
    },
    
    // --- ЧАТ ---
    'chat_title': {
      Language.ru: 'AI Ассистент',
      Language.kz: 'AI Көмекші',
      Language.en: 'AI Assistant',
    },
    'chat_hint': {
      Language.ru: 'Спроси о финансах...',
      Language.kz: 'Қаржы туралы сұраңыз...',
      Language.en: 'Ask about finances...',
    },
    'chat_empty_message': {
      Language.ru: 'Загрузите выписку, чтобы начать чат',
      Language.kz: 'Чатты бастау үшін үзіндіні жүктеңіз',
      Language.en: 'Upload a statement to start chatting',
    },
    
    // --- ПРОФИЛЬ ---
    'profile_title': {
      Language.ru: 'Профиль',
      Language.kz: 'Профиль',
      Language.en: 'Profile',
    },
    'profile_guest': {
      Language.ru: 'Гость',
      Language.kz: 'Қонақ',
      Language.en: 'Guest',
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
      Language.ru: 'Статус: Бесплатный',
      Language.kz: 'Статус: Тегін',
      Language.en: 'Status: Free',
    },
    'status_premium': {
      Language.ru: 'Статус: PRO',
      Language.kz: 'Статус: PRO',
      Language.en: 'Status: PRO',
    },
    'limit_requests': {
      Language.ru: 'Лимит: 5 запросов',
      Language.kz: 'Шектеу: 5 сұрау',
      Language.en: 'Limit: 5 requests',
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
      Language.ru: 'Улучшить',
      Language.kz: 'Жақсарту',
      Language.en: 'Upgrade',
    },
    
    // --- WELCOME SCREEN ---
    'welcome_title': {
      Language.ru: 'FinSight',
      Language.kz: 'FinSight',
      Language.en: 'FinSight',
    },
    'welcome_subtitle': {
      Language.ru: 'Твой умный финансовый ассистент',
      Language.kz: 'Сенің ақылды қаржы көмекшің',
      Language.en: 'Your smart financial assistant',
    },
    'welcome_feature1': {
      Language.ru: 'Загрузи выписку Kaspi PDF',
      Language.kz: 'Kaspi үзіндісін PDF жүкте',
      Language.en: 'Upload Kaspi statement PDF',
    },
    'welcome_feature2': {
      Language.ru: 'Получи аналитику и советы',
      Language.kz: 'Талдау мен кеңестер алыңыз',
      Language.en: 'Get analytics and advice',
    },
    'welcome_feature3': {
      Language.ru: 'Общайся с AI о финансах',
      Language.kz: 'AI-мен қаржы туралы сөйлес',
      Language.en: 'Chat with AI about finances',
    },
    'welcome_button': {
      Language.ru: 'Начать анализ',
      Language.kz: 'Талдауды бастау',
      Language.en: 'Start Analysis',
    },
    
    // --- REGISTRATION SCREEN ---
    'registration_title': {
      Language.ru: 'Как тебя зовут?',
      Language.kz: 'Сенің атың кім?',
      Language.en: 'What\'s your name?',
    },
    'registration_subtitle': {
      Language.ru: 'Расскажи нам немного о себе',
      Language.kz: 'Өзің туралы біраз айтып бер',
      Language.en: 'Tell us a bit about yourself',
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
      Language.ru: 'FinSight PRO',
      Language.kz: 'FinSight PRO',
      Language.en: 'FinSight PRO',
    },
    'premium_subtitle': {
      Language.ru: 'Разблокируй полную мощь AI',
      Language.kz: 'AI-дың толық қуатын ашыңыз',
      Language.en: 'Unlock the full power of AI',
    },
    'premium_feature1': {
      Language.ru: 'Безлимитные вопросы к AI',
      Language.kz: 'AI-ға шексіз сұрақтар',
      Language.en: 'Unlimited AI questions',
    },
    'premium_feature2': {
      Language.ru: 'Глубокий анализ долгов',
      Language.kz: 'Қарыздарды терең талдау',
      Language.en: 'Deep debt analysis',
    },
    'premium_feature3': {
      Language.ru: 'Экспорт отчетов в Excel',
      Language.kz: 'Есептерді Excel-ге экспорттау',
      Language.en: 'Export reports to Excel',
    },
    'premium_feature4': {
      Language.ru: 'Семейный доступ',
      Language.kz: 'Отбасылық қол жетімділік',
      Language.en: 'Family access',
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
      Language.ru: 'Привет! Я твой финансовый ассистент FinSight. Я могу помочь тебе с анализом расходов, планированием бюджета и финансовыми советами. Загрузи выписку, чтобы я мог дать более точные рекомендации!',
      Language.kz: 'Сәлем! Мен сенің қаржы көмекшің FinSight. Мен шығындарды талдауға, бюджетті жоспарлауға және қаржылық кеңестерге көмектесе аламын. Дәлірек ұсыныстар беру үшін үзіндіні жүкте!',
      Language.en: 'Hello! I\'m your financial assistant FinSight. I can help you with expense analysis, budget planning, and financial advice. Upload a statement so I can give you more accurate recommendations!',
    },
    'chat_typing': {
      Language.ru: 'AI печатает...',
      Language.kz: 'AI теріп жатыр...',
      Language.en: 'AI typing...',
    },
    'chat_suggestion1': {
      Language.ru: '📉 Как мне сэкономить?',
      Language.kz: '📉 Қалай үнемдеуге болады?',
      Language.en: '📉 How can I save money?',
    },
    'chat_suggestion2': {
      Language.ru: '🏆 Топ моих расходов?',
      Language.kz: '🏆 Менің шығындарымның топы?',
      Language.en: '🏆 Top of my expenses?',
    },
    'chat_suggestion3': {
      Language.ru: '🔮 Прогноз на месяц',
      Language.kz: '🔮 Айға болжам',
      Language.en: '🔮 Forecast for the month',
    },
    'chat_suggestion4': {
      Language.ru: '🍔 Сколько ушло на еду?',
      Language.kz: '🍔 Тағамға қанша кетті?',
      Language.en: '🍔 How much spent on food?',
    },
    'chat_suggestion5': {
      Language.ru: '🚕 Много ли я трачу на такси?',
      Language.kz: '🚕 Таксиге көп жұмсаймын ба?',
      Language.en: '🚕 Do I spend a lot on taxis?',
    },
    'chat_suggestion6': {
      Language.ru: '💳 Есть ли скрытые подписки?',
      Language.kz: '💳 Жасырын жазылымдар бар ма?',
      Language.en: '💳 Are there hidden subscriptions?',
    },
    'chat_error': {
      Language.ru: 'Ошибка связи с AI 😔',
      Language.kz: 'AI-мен байланыс қатесі 😔',
      Language.en: 'AI connection error 😔',
    },
    
    // --- MAIN SCREEN ---
    'ai_chat_button': {
      Language.ru: 'AI Чат',
      Language.kz: 'AI Чат',
      Language.en: 'AI Chat',
    },
    'app_title': {
      Language.ru: 'FinSight',
      Language.kz: 'FinSight',
      Language.en: 'FinSight',
    },
    'dashboard_title': {
      Language.ru: 'Дашборд',
      Language.kz: 'Бақылау тақтасы',
      Language.en: 'Dashboard',
    },
    
    // --- LIMIT DIALOGS ---
    'limit_exceeded_title': {
      Language.ru: 'Лимит исчерпан',
      Language.kz: 'Шектеу аяқталды',
      Language.en: 'Limit Exceeded',
    },
    'limit_exceeded_message': {
      Language.ru: 'Вы использовали все бесплатные действия. Перейдите на PRO для безлимитного доступа.',
      Language.kz: 'Сіз барлық тегін әрекеттерді пайдаландыңыз. Шексіз қол жетімділік үшін PRO-ға өтіңіз.',
      Language.en: 'You have used all free actions. Upgrade to PRO for unlimited access.',
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
    
    // --- PERIOD FILTER ---
    'period_week': {
      Language.ru: 'Неделя',
      Language.kz: 'Апта',
      Language.en: 'Week',
    },
    'period_month': {
      Language.ru: 'Месяц',
      Language.kz: 'Ай',
      Language.en: 'Month',
    },
    'period_all': {
      Language.ru: 'Все',
      Language.kz: 'Барлығы',
      Language.en: 'All',
    },
    'recent_transactions': {
      Language.ru: 'Последние транзакции',
      Language.kz: 'Соңғы транзакциялар',
      Language.en: 'Recent Transactions',
    },
    
    // --- GOALS SCREEN ---
    'goals_title': {
      Language.ru: 'Цели',
      Language.kz: 'Қаржылық мақсаттар',
      Language.en: 'Financial Goals',
    },
    'goals_subtitle': {
      Language.ru: 'Укажите вашу финансовую цель и доход, чтобы получать более персонализированные советы',
      Language.kz: 'Жекеленген кеңестер алу үшін қаржылық мақсатыңызды және табысыңызды көрсетіңіз',
      Language.en: 'Specify your financial goal and income to receive more personalized advice',
    },
    'goals_goal_label': {
      Language.ru: 'Ваша финансовая цель',
      Language.kz: 'Сіздің қаржылық мақсатыңыз',
      Language.en: 'Your Financial Goal',
    },
    'goals_goal_hint': {
      Language.ru: 'Например: Накопить 1 млн на машину',
      Language.kz: 'Мысалы: Көлікке 1 млн жинау',
      Language.en: 'For example: Save 1 million for a car',
    },
    'goals_income_label': {
      Language.ru: 'Ваш ежемесячный доход',
      Language.kz: 'Сіздің айлық табысыңыз',
      Language.en: 'Your Monthly Income',
    },
    'goals_income_hint': {
      Language.ru: 'Выберите диапазон дохода',
      Language.kz: 'Табыс диапазонын таңдаңыз',
      Language.en: 'Select income range',
    },
    'goals_save_button': {
      Language.ru: 'Сохранить',
      Language.kz: 'Сақтау',
      Language.en: 'Save',
    },
    'goals_saved': {
      Language.ru: 'Цель успешно сохранена!',
      Language.kz: 'Мақсат сәтті сақталды!',
      Language.en: 'Goal saved successfully!',
    },
    'goals_error_empty': {
      Language.ru: 'Пожалуйста, укажите финансовую цель',
      Language.kz: 'Қаржылық мақсатты көрсетіңіз',
      Language.en: 'Please specify your financial goal',
    },
    'goals_error_save': {
      Language.ru: 'Ошибка при сохранении',
      Language.kz: 'Сақтау кезінде қате',
      Language.en: 'Error saving',
    },
    'goals_menu_item': {
      Language.ru: 'Финансовые цели',
      Language.kz: 'Қаржылық мақсаттар',
      Language.en: 'Financial Goals',
    },
    'goals_saved_list_title': {
      Language.ru: 'Сохраненные цели',
      Language.kz: 'Сақталған мақсаттар',
      Language.en: 'Saved Goals',
    },
    'goals_income_option1': {
      Language.ru: 'До 100 000 ₸',
      Language.kz: '100 000 ₸ дейін',
      Language.en: 'Up to 100,000 ₸',
    },
    'goals_income_option2': {
      Language.ru: '100 000 - 200 000 ₸',
      Language.kz: '100 000 - 200 000 ₸',
      Language.en: '100,000 - 200,000 ₸',
    },
    'goals_income_option3': {
      Language.ru: '200 000 - 300 000 ₸',
      Language.kz: '200 000 - 300 000 ₸',
      Language.en: '200,000 - 300,000 ₸',
    },
    'goals_income_option4': {
      Language.ru: '300 000 - 500 000 ₸',
      Language.kz: '300 000 - 500 000 ₸',
      Language.en: '300,000 - 500,000 ₸',
    },
    'goals_income_option5': {
      Language.ru: '500 000 - 1 000 000 ₸',
      Language.kz: '500 000 - 1 000 000 ₸',
      Language.en: '500,000 - 1,000,000 ₸',
    },
    'goals_income_option6': {
      Language.ru: 'Свыше 1 000 000 ₸',
      Language.kz: '1 000 000 ₸ астам',
      Language.en: 'Over 1,000,000 ₸',
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
      Language.ru: 'Для доступа к приложению',
      Language.kz: 'Қолданбаға кіру үшін',
      Language.en: 'To access the app',
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
      Language.ru: 'Вход в приложение',
      Language.kz: 'Қолданбаға кіру',
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