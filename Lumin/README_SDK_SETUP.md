# Настройка Supabase SDK для Lumin

## 1. Установка Supabase Swift SDK

### Вариант A: Через Swift Package Manager (рекомендуется)

1. Откройте проект в Xcode
2. Выберите File → Add Package Dependencies
3. Вставьте URL: `https://github.com/supabase-community/supabase-swift.git`
4. Выберите версию: `2.3.0` или выше
5. Нажмите "Add Package"

### Вариант B: Через Package.swift

Если у вас есть Package.swift, добавьте зависимость:

```swift
dependencies: [
    .package(url: "https://github.com/supabase-community/supabase-swift.git", from: "2.3.0")
]
```

## 2. Обновление базы данных

Выполните SQL скрипт `add_favorites_column.sql` в Supabase Dashboard:

```sql
-- Добавляем поле favorite_outfits в таблицу users
ALTER TABLE users ADD COLUMN IF NOT EXISTS favorite_outfits JSONB DEFAULT '[]';

-- Проверяем, что поле добавлено
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'users' AND column_name = 'favorite_outfits';

-- Обновляем политики для нового поля
CREATE POLICY "Allow read own favorites" ON users
    FOR SELECT USING (auth.uid()::text = id::text);

CREATE POLICY "Allow update own favorites" ON users
    FOR UPDATE USING (auth.uid()::text = id::text);
```

## 3. Преимущества SDK над REST API

### Безопасность
- ✅ Автоматическое управление токенами
- ✅ Встроенная аутентификация
- ✅ Защита от SQL-инъекций

### Удобство
- ✅ Типобезопасные запросы
- ✅ Автоматическая сериализация/десериализация
- ✅ Встроенная обработка ошибок

### Читаемость
- ✅ Чистый и понятный код
- ✅ Меньше boilerplate кода
- ✅ Лучшая поддержка IDE

## 4. Основные изменения в коде

### AuthManager
- Использует `supabaseClient.auth.signUp()` вместо REST API
- Автоматическое управление сессиями
- Упрощенная обработка ошибок

### NetworkManager
- Использует `supabaseClient.from().select()` для запросов
- Встроенная пагинация через `.range()`
- Автоматическая загрузка файлов через Storage API

### Логирование
- Добавлены подробные логи для отладки
- Четкие сообщения об ошибках
- Отслеживание всех операций

## 5. Тестирование

После установки SDK протестируйте:

1. **Регистрация пользователя** - проверьте логи в консоли
2. **Вход в систему** - убедитесь, что сессия создается
3. **Создание наряда** - проверьте загрузку изображений
4. **Избранное** - протестируйте добавление/удаление из избранного
5. **Удаление наряда** - проверьте удаление из БД и Storage

## 6. Устранение неполадок

### Ошибка "Package not found"
- Проверьте подключение к интернету
- Убедитесь, что URL пакета правильный
- Попробуйте очистить кэш Xcode (Product → Clean Build Folder)

### Ошибки компиляции
- Убедитесь, что импортирован `import Supabase`
- Проверьте версию Swift (требуется 5.9+)
- Проверьте версию iOS (требуется 15.0+)

### Ошибки в базе данных
- Выполните SQL скрипт `add_favorites_column.sql`
- Проверьте RLS политики в Supabase Dashboard
- Убедитесь, что bucket "outfit-images" создан

## 7. Логи для отладки

Все операции теперь логируются с префиксами:
- 🔧 Инициализация
- 🚀 Начало операции
- ✅ Успешное завершение
- ❌ Ошибки
- ⚠️ Предупреждения
- 🔍 Отладочная информация
- 💾 Операции с UserDefaults
- 💖 Операции с избранным
- ��️ Удаление данных 