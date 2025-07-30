# Lumin - Приложение для обмена образами

Lumin - это iOS приложение, которое позволяет пользователям делиться своими готовыми образами (outfits) и прикреплять ссылки на отдельные элементы гардероба для покупки.

## 🚀 Возможности

- **Поиск нарядов** с фильтрацией по сезону, полу, возрасту
- **Избранное** - сохранение понравившихся образов
- **Профиль пользователя** с социальными ссылками
- **Создание нарядов** с загрузкой фотографий
- **Детальный просмотр** с возможностью копирования артикулов
- **Аутентификация пользователей**

## 🏗️ Архитектура

Приложение построено на архитектуре **MVVM** с использованием:
- **SwiftUI** для UI
- **Combine** для реактивного программирования
- **Supabase** для backend (база данных и аутентификация)

## 📱 Основные экраны

1. **Поиск** - лента нарядов с фильтрами и поиском по авторам
2. **Избранное** - сохраненные пользователем наряды
3. **Профиль** - информация о пользователе и созданные им наряды

## 🛠️ Настройка проекта

### 1. Создание проекта Supabase

1. Перейдите на [supabase.com](https://supabase.com)
2. Создайте новый проект
3. Получите URL проекта и anon key

### 2. Настройка базы данных

Выполните следующие SQL команды в Supabase SQL Editor:

```sql
-- Таблица нарядов
CREATE TABLE outfits (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  author TEXT NOT NULL,
  photos TEXT[] NOT NULL,
  items JSONB NOT NULL,
  season TEXT NOT NULL,
  gender TEXT NOT NULL,
  age_group TEXT NOT NULL,
  is_favorite BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Таблица пользователей
CREATE TABLE users (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  email TEXT UNIQUE NOT NULL,
  profile_image TEXT,
  social_links JSONB DEFAULT '[]',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Настройка RLS
ALTER TABLE outfits ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Политики для outfits
CREATE POLICY "Allow public read access" ON outfits
  FOR SELECT USING (true);

CREATE POLICY "Allow authenticated insert" ON outfits
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Allow update own outfits" ON outfits
  FOR UPDATE USING (auth.uid()::text = author);

CREATE POLICY "Allow delete own outfits" ON outfits
  FOR DELETE USING (auth.uid()::text = author);
```

### 3. Настройка Storage

1. В Supabase Dashboard перейдите в Storage
2. Создайте новый bucket с именем `outfit-images`
3. Настройте публичный доступ для чтения

### 4. Обновление конфигурации

Откройте файл `Config/SupabaseConfig.swift` и замените:

```swift
static let projectURL = "https://your-project.supabase.co"
static let anonKey = "your-anon-key"
```

На ваши реальные данные из Supabase.

## 📦 Установка и запуск

1. Клонируйте репозиторий
2. Откройте проект в Xcode
3. Настройте Supabase (см. выше)
4. Запустите приложение на симуляторе или устройстве

## 🔧 Структура проекта

```
Lumin/
├── Models/
│   ├── Outfits.swift          # Модели данных
│   ├── OutfitData.swift       # ViewModel для нарядов
│   ├── ProfileViewModel.swift # ViewModel для профиля
│   ├── AuthManager.swift      # Управление аутентификацией
│   └── NetworkManager.swift   # Сетевой слой
├── Views/
│   ├── AuthView.swift         # Экран аутентификации
│   ├── SearchView.swift       # Экран поиска
│   ├── FavoritesView.swift    # Экран избранного
│   ├── ProfileView.swift      # Экран профиля
│   ├── CreateOutfitView.swift # Создание наряда
│   ├── OutfitCardView.swift   # Карточка наряда
│   ├── OutfitDetailView.swift # Детальный просмотр
│   └── ImagePicker.swift      # Выбор изображений
├── Config/
│   └── SupabaseConfig.swift   # Конфигурация Supabase
└── Assets.xcassets/           # Ресурсы приложения
```

## 🎨 Дизайн

Приложение использует современный дизайн с:
- Прямоугольными карточками без скругления углов
- 2-колоночной сеткой для быстрого просмотра
- Минималистичным интерфейсом
- Адаптивной типографикой

## 🔄 Основные функции

### Создание наряда
1. Нажмите "Новый наряд" в профиле
2. Добавьте фотографии (из галереи или камеры)
3. Выберите сезон, пол, возрастную группу
4. Добавьте элементы гардероба с артикулами
5. Сохраните наряд

### Поиск и фильтрация
- Используйте поисковую строку для поиска по авторам
- Применяйте фильтры по сезону, полу, возрасту
- Добавляйте понравившиеся наряды в избранное

### Детальный просмотр
- Листайте фотографии свайпами
- Копируйте артикулы элементов гардероба
- Просматривайте полную информацию о наряде

## 🚧 TODO

- [ ] Интеграция с Supabase Auth
- [ ] Загрузка изображений в Supabase Storage
- [ ] Push-уведомления
- [ ] Комментарии к нарядам
- [ ] Лайки и рейтинги
- [ ] Поиск по артикулам
- [ ] Интеграция с Wildberries API

## 📄 Лицензия

MIT License

## 👥 Автор

Андрей Прудников 