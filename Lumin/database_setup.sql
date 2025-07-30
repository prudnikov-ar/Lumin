-- SQL скрипт для настройки базы данных Supabase для приложения Lumin

-- 1. Создание таблицы пользователей
CREATE TABLE IF NOT EXISTS users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    profile_image TEXT,
    social_links JSONB DEFAULT '[]',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Создание таблицы нарядов
CREATE TABLE IF NOT EXISTS outfits (
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

-- 3. Создание индексов для улучшения производительности
CREATE INDEX IF NOT EXISTS idx_outfits_author ON outfits(author);
CREATE INDEX IF NOT EXISTS idx_outfits_season ON outfits(season);
CREATE INDEX IF NOT EXISTS idx_outfits_gender ON outfits(gender);
CREATE INDEX IF NOT EXISTS idx_outfits_age_group ON outfits(age_group);
CREATE INDEX IF NOT EXISTS idx_outfits_created_at ON outfits(created_at DESC);

-- 4. Создание функции для автоматического обновления updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 5. Создание триггеров для автоматического обновления updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_outfits_updated_at BEFORE UPDATE ON outfits
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 6. Настройка Row Level Security (RLS)

-- Включаем RLS для таблиц
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE outfits ENABLE ROW LEVEL SECURITY;

-- Политики для таблицы users
-- Разрешить чтение всех пользователей
CREATE POLICY "Allow public read access to users" ON users
    FOR SELECT USING (true);

-- Разрешить создание пользователей авторизованным пользователям
CREATE POLICY "Allow authenticated insert to users" ON users
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Разрешить обновление своих данных
CREATE POLICY "Allow update own user data" ON users
    FOR UPDATE USING (auth.uid()::text = id::text);

-- Политики для таблицы outfits
-- Разрешить чтение всех нарядов
CREATE POLICY "Allow public read access to outfits" ON outfits
    FOR SELECT USING (true);

-- Разрешить создание нарядов авторизованным пользователям
CREATE POLICY "Allow authenticated insert to outfits" ON outfits
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Разрешить обновление своих нарядов
CREATE POLICY "Allow update own outfits" ON outfits
    FOR UPDATE USING (auth.uid()::text = author);

-- Разрешить удаление своих нарядов
CREATE POLICY "Allow delete own outfits" ON outfits
    FOR DELETE USING (auth.uid()::text = author);

-- 7. Создание Storage bucket для изображений
-- Примечание: Этот bucket нужно создать вручную в Supabase Dashboard
-- Название: outfit-images
-- Публичный доступ: Да
-- File size limit: 5MB
-- Allowed MIME types: image/*

-- 8. Настройка Storage policies
-- Разрешить публичное чтение изображений
CREATE POLICY "Allow public read access to storage" ON storage.objects
    FOR SELECT USING (bucket_id = 'outfit-images');

-- Разрешить загрузку изображений авторизованным пользователям
CREATE POLICY "Allow authenticated upload to storage" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'outfit-images' 
        AND auth.role() = 'authenticated'
    );

-- Разрешить удаление своих изображений
CREATE POLICY "Allow delete own storage objects" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'outfit-images' 
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- 9. Создание представления для популярных нарядов
CREATE OR REPLACE VIEW popular_outfits AS
SELECT 
    o.*,
    COUNT(*) as view_count
FROM outfits o
LEFT JOIN outfit_views ov ON o.id = ov.outfit_id
GROUP BY o.id
ORDER BY view_count DESC, o.created_at DESC;

-- 10. Создание таблицы для отслеживания просмотров (опционально)
CREATE TABLE IF NOT EXISTS outfit_views (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    outfit_id UUID REFERENCES outfits(id) ON DELETE CASCADE,
    viewer_id TEXT,
    viewed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Индекс для таблицы просмотров
CREATE INDEX IF NOT EXISTS idx_outfit_views_outfit_id ON outfit_views(outfit_id);
CREATE INDEX IF NOT EXISTS idx_outfit_views_viewed_at ON outfit_views(viewed_at);

-- Политики для таблицы просмотров
ALTER TABLE outfit_views ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access to outfit_views" ON outfit_views
    FOR SELECT USING (true);

CREATE POLICY "Allow authenticated insert to outfit_views" ON outfit_views
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Комментарии к таблицам
COMMENT ON TABLE users IS 'Таблица пользователей приложения Lumin';
COMMENT ON TABLE outfits IS 'Таблица нарядов пользователей';
COMMENT ON TABLE outfit_views IS 'Таблица для отслеживания просмотров нарядов';
COMMENT ON VIEW popular_outfits IS 'Представление популярных нарядов'; 