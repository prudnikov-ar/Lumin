-- SQL скрипт для настройки Supabase Storage для приложения Lumin

-- 1. Создание Storage bucket (выполните в Supabase Dashboard -> Storage)
-- Название: outfit-images
-- Публичный доступ: Да
-- File size limit: 5MB
-- Allowed MIME types: image/*

-- 2. Настройка Storage политик

-- Разрешить публичное чтение изображений
CREATE POLICY "Allow public read access to storage" ON storage.objects
    FOR SELECT USING (bucket_id = 'outfit-images');

-- Разрешить загрузку изображений авторизованным пользователям
CREATE POLICY "Allow authenticated upload to storage" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'outfit-images' 
        AND auth.role() = 'authenticated'
    );

-- Разрешить загрузку изображений анонимным пользователям (для тестирования)
CREATE POLICY "Allow anonymous upload to storage" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'outfit-images'
    );

-- Разрешить удаление своих изображений
CREATE POLICY "Allow delete own storage objects" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'outfit-images' 
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Разрешить обновление своих изображений
CREATE POLICY "Allow update own storage objects" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'outfit-images' 
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- 3. Дополнительные политики для профильных изображений
CREATE POLICY "Allow public read access to profile images" ON storage.objects
    FOR SELECT USING (bucket_id = 'outfit-images' AND name LIKE 'profile_%');

CREATE POLICY "Allow authenticated upload profile images" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'outfit-images' 
        AND name LIKE 'profile_%'
        AND auth.role() = 'authenticated'
    );

-- 4. Проверка существующих политик
-- Выполните в SQL Editor для проверки:
/*
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'objects';
*/

-- 5. Создание функции для очистки старых файлов (опционально)
CREATE OR REPLACE FUNCTION cleanup_old_files()
RETURNS void AS $$
BEGIN
    -- Удаляем файлы старше 30 дней
    DELETE FROM storage.objects 
    WHERE bucket_id = 'outfit-images' 
    AND created_at < NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;

-- 6. Создание триггера для автоматической очистки (опционально)
-- CREATE EVENT TRIGGER cleanup_storage_files ON scheduled_event
-- EXECUTE FUNCTION cleanup_old_files();

-- 7. Проверка настроек bucket
-- Выполните в SQL Editor для проверки:
/*
SELECT 
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
FROM storage.buckets 
WHERE name = 'outfit-images';
*/ 