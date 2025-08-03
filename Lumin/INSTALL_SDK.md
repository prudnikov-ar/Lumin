# Установка Supabase SDK и исправление ошибок

## 🚀 Быстрая установка SDK

### 1. Добавьте SDK в Xcode:
1. Откройте проект в Xcode
2. File → Add Package Dependencies
3. Вставьте URL: `https://github.com/supabase-community/supabase-swift.git`
4. Выберите версию: `2.3.0` или выше
5. Нажмите "Add Package"

### 2. Выполните SQL скрипт в Supabase:
```sql
-- Добавляем поле favorite_outfits в таблицу users
ALTER TABLE users ADD COLUMN IF NOT EXISTS favorite_outfits JSONB DEFAULT '[]';

-- Создаем политики для нового поля
CREATE POLICY "Allow read own favorites" ON users
    FOR SELECT USING (auth.uid()::text = id::text);

CREATE POLICY "Allow update own favorites" ON users
    FOR UPDATE USING (auth.uid()::text = id::text);
```

## ✅ Исправленные ошибки

### 1. Типы данных AnyJSON
- Исправлено: `["username": username]` → `["username": AnyJSON.string(username)]`
- Исправлено: `["is_favorite": isFavorite]` → `["is_favorite": AnyJSON.boolean(isFavorite)]`
- Исправлено: `["favorite_outfits": newFavorites]` → `["favorite_outfits": AnyJSON.array(newFavorites.map { AnyJSON.string($0) })]`

### 2. Асинхронные функции
- Исправлено: `func signOut()` → `func signOut() async`
- Добавлены `Task { await ... }` для вызовов асинхронных функций

### 3. Модель User
- Удалено поле `outfits` из модели User (вызывало ошибку Decodable)
- Оставлены только необходимые поля для работы с базой данных

### 4. UserMetadata
- Исправлено: `session.user.userMetadata?["username"]` → `session.user.userMetadata["username"]?.stringValue`

## 🔧 Основные изменения

### AuthManager.swift
- ✅ Использует `supabaseClient.auth.signUp()` и `supabaseClient.auth.signIn()`
- ✅ Автоматическое управление сессиями
- ✅ Подробное логирование

### NetworkManager.swift
- ✅ Использует `supabaseClient.from().select()` для запросов
- ✅ Встроенная пагинация через `.range()`
- ✅ Автоматическая загрузка файлов

### SupabaseConfig.swift
- ✅ Добавлен `static let client = SupabaseClient(...)`
- ✅ Импорт `import Supabase`

## 🧪 Тестирование

После установки протестируйте:
1. ✅ Регистрация пользователя
2. ✅ Вход в систему
3. ✅ Создание наряда
4. ✅ Загрузка изображений
5. ✅ Избранное
6. ✅ Удаление наряда

## 📊 Логирование

Все операции логируются с эмодзи:
- 🔧 Инициализация
- 🚀 Начало операции
- ✅ Успех
- ❌ Ошибки
- ⚠️ Предупреждения
- 💖 Избранное
- 🗑️ Удаление

## 🎯 Результат

Теперь код:
- ✅ Более безопасный (автоматические токены)
- ✅ Более читаемый (меньше boilerplate)
- ✅ Более производительный (оптимизированные запросы)
- ✅ Лучше поддерживается (типобезопасность) 