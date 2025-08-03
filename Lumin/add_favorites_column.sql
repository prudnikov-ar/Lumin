-- SQL скрипт для добавления поля favorite_outfits в таблицу users

-- Добавляем поле favorite_outfits в таблицу users
ALTER TABLE users ADD COLUMN IF NOT EXISTS favorite_outfits JSONB DEFAULT '[]';

-- Проверяем, что поле добавлено
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'users' AND column_name = 'favorite_outfits';

-- Обновляем политики для нового поля
-- Разрешить чтение favorite_outfits для авторизованных пользователей
CREATE POLICY "Allow read own favorites" ON users
    FOR SELECT USING (auth.uid()::text = id::text);

-- Разрешить обновление favorite_outfits для авторизованных пользователей
CREATE POLICY "Allow update own favorites" ON users
    FOR UPDATE USING (auth.uid()::text = id::text); 