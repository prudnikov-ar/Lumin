# Структура Views

Этот каталог содержит все UI компоненты приложения, организованные по функциональности.

## Структура папок

### 📁 Components/
Переиспользуемые UI компоненты, разделенные по категориям:

#### 📁 Components/Profile/
- `ProfileHeaderView.swift` - Заголовок профиля с аватаром и ником
- `UserOutfitsView.swift` - Секция "Мои наряды" 
- `CreateOutfitButton.swift` - Кнопка создания нового наряда

#### 📁 Components/Outfit/
- `PhotoUploadSection.swift` - Секция загрузки фотографий
- `OutfitInfoSection.swift` - Секция основной информации о наряде
- `OutfitItemsSection.swift` - Секция элементов одежды
- `OutfitGalleryView.swift` - Галерея фотографий наряда
- `OutfitInfoView.swift` - Информация о наряде в детальном просмотре

#### 📁 Components/Search/
- `SearchHeaderView.swift` - Заголовок поиска с кнопками
- `ActiveFiltersView.swift` - Активные фильтры
- `OutfitsGridView.swift` - Сетка нарядов с ленивой загрузкой

#### 📁 Components/Common/
- `CommonComponents.swift` - Общие компоненты (LoadingView, ErrorView, EmptyStateView)

### 📁 Profile/
Основные экраны профиля:
- `ProfileView.swift` - Главный экран профиля

### 📁 Outfit/
Экраны, связанные с нарядами:
- `CreateOutfitView.swift` - Создание нового наряда
- `OutfitDetailView.swift` - Детальный просмотр наряда
- `OutfitCardView.swift` - Карточка наряда
- `EditItemView.swift` - Редактирование элемента одежды
- `AddItemView.swift` - Добавление нового элемента
- `FavoritesView.swift` - Избранные наряды

### 📁 Search/
Экраны поиска и фильтрации:
- `SearchView.swift` - Главный экран поиска
- `FilterView.swift` - Экран фильтров

### 📁 Auth/
Экраны аутентификации:
- `AuthView.swift` - Экран входа/регистрации

### 📁 Storage/
Экраны для работы с хранилищем:
- `ImageUploadView.swift` - Загрузка изображений
- `StorageTestView.swift` - Тестирование хранилища

### 📁 Common/
Общие компоненты:
- `ImagePicker.swift` - Выбор изображений

## Принципы организации

1. **Разделение по функциональности** - каждый каталог отвечает за определенную область приложения
2. **Переиспользование компонентов** - общие UI элементы вынесены в Components
3. **Компактность** - каждый файл содержит логически связанный код
4. **Читаемость** - понятные имена файлов и папок

## Использование

При создании новых экранов:
1. Определите функциональную область
2. Поместите файл в соответствующую папку
3. Вынесите переиспользуемые компоненты в Components
4. Обновите этот README при необходимости 