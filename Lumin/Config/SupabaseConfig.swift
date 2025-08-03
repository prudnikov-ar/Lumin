//
//  SupabaseConfig.swift
//  Lumin
//
//  Created by Андрей Прудников on 29.06.2025.
//

import Foundation
import Supabase

struct SupabaseConfig {
    // Конфигурация Supabase
    static let projectURL = "https://bmnzugozbvpeurndgiba.supabase.co"
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJtbnp1Z296YnZwZXVybmRnaWJhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM4NjMyMzMsImV4cCI6MjA2OTQzOTIzM30.nXKBOY9iPT5WaQVECNgjlcQZJozKbUPgoUBsxlD68II"
    
    // Настройки для загрузки изображений
    static let storageBucket = "outfit-images"
    static let maxImageSize = 5 * 1024 * 1024 // 5MB
    
    // Настройки для API
    static let timeoutInterval: TimeInterval = 30
    static let maxRetries = 3
    
    // Создание клиента Supabase
    static let client = SupabaseClient(
        supabaseURL: URL(string: projectURL)!,
        supabaseKey: anonKey
    )
}

// MARK: - Database Schema
/*
 
 Создайте следующие таблицы в Supabase:
 
 1. outfits (наряды)
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

 2. users (пользователи)
 CREATE TABLE users (
   id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
   username TEXT UNIQUE NOT NULL,
   email TEXT UNIQUE NOT NULL,
   profile_image TEXT,
   social_links JSONB DEFAULT '[]',
   created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
   updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
 );

 3. Создайте Storage bucket "outfit-images" для загрузки фотографий
 
 4. Настройте Row Level Security (RLS):
 
 -- Разрешить чтение всех нарядов
 CREATE POLICY "Allow public read access" ON outfits
   FOR SELECT USING (true);
 
 -- Разрешить создание нарядов авторизованным пользователям
 CREATE POLICY "Allow authenticated insert" ON outfits
   FOR INSERT WITH CHECK (auth.role() = 'authenticated');
 
 -- Разрешить обновление своих нарядов не нужно так как редактировать свои посты никак нельзя а только удалять (это политика моего приложения)
 
 -- Разрешить удаление своих нарядов
 CREATE POLICY "Allow delete own outfits" ON outfits
   FOR DELETE USING (auth.uid()::text = author);
 
 */ 
