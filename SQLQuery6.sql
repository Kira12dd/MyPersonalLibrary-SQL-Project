USE MyPersonalLibrary;
GO

-- 1. Створення логінів (Рівень сервера - АВТЕНТИФІКАЦІЯ)

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'Library_Admin')
    CREATE LOGIN Library_Admin WITH PASSWORD = 'StrongPassword123!';

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'Reader_Guest')
    CREATE LOGIN Reader_Guest WITH PASSWORD = 'StrongPassword123!';

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'Data_Operator')
    CREATE LOGIN Data_Operator WITH PASSWORD = 'StrongPassword123!';
GO

-- 2. Створення користувачів (Рівень БД - АВТОРИЗАЦІЯ)

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Library_Admin_User')
    CREATE USER Library_Admin_User FOR LOGIN Library_Admin;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Reader_Guest_User')
    CREATE USER Reader_Guest_User FOR LOGIN Reader_Guest;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Data_Operator_User')
    CREATE USER Data_Operator_User FOR LOGIN Data_Operator;
GO


-- 3. Створення ролей та надання привілеїв ролям (Пункт 3, 4)

-- Роль 1: Менеджер бібліотеки (Повний контроль над усіма таблицями метаданих)
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Library_Manager_Role' AND type = 'R')
    CREATE ROLE Library_Manager_Role;

-- Права на книги, авторів, жанри, теги, видавництва
GRANT SELECT, INSERT, UPDATE, DELETE ON Books TO Library_Manager_Role;
GRANT SELECT, INSERT, UPDATE, DELETE ON Authors TO Library_Manager_Role;
GRANT SELECT, INSERT, UPDATE, DELETE ON Genres TO Library_Manager_Role;
GRANT SELECT, INSERT, UPDATE, DELETE ON Tags TO Library_Manager_Role;
GRANT SELECT, INSERT, UPDATE, DELETE ON Publishers TO Library_Manager_Role;

-- Права на таблиці-зв'язки
GRANT SELECT, INSERT, UPDATE, DELETE ON BookAuthors TO Library_Manager_Role;
GRANT SELECT, INSERT, UPDATE, DELETE ON BookGenres TO Library_Manager_Role;
GRANT SELECT, INSERT, UPDATE, DELETE ON BookTags TO Library_Manager_Role;

-- Дозвіл на запуск аналітичних процедур (ЛР 3)
GRANT EXECUTE TO Library_Manager_Role;

-- Роль 2: Гість-читач (Перегляд усіх звітів)
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Library_Viewer_Role' AND type = 'R')
    CREATE ROLE Library_Viewer_Role;

GRANT SELECT ON v_FullLibraryReport TO Library_Viewer_Role;
GRANT SELECT ON v_MyShelf TO Library_Viewer_Role;
GRANT SELECT ON v_BookRatings TO Library_Viewer_Role;
GO

-- 4. Призначення ролей користувачам (Пункт 5)

ALTER ROLE Library_Manager_Role ADD MEMBER Data_Operator_User;
ALTER ROLE Library_Viewer_Role ADD MEMBER Reader_Guest_User;
GO

-- 5. Персональні привілеї та перевірка логіки (Пункти 2, 6, 7)

-- Надамо персональне право оператору
GRANT SELECT ON Books TO Data_Operator_User;

-- Пункт 6: Відкликаємо персональне право, але доступ залишається через роль
REVOKE SELECT ON Books FROM Data_Operator_User;
GO

--Перевірка для Оператора (Пункт 6):
EXECUTE AS USER = 'Data_Operator_User';
-- Навіть після REVOKE цей запит має працювати (завдяки ролі Library_Manager_Role)
SELECT * FROM Books; 
REVERT; -- Повертаємося до прав адміна

-- Пункт 7: Надамо гостю персональне право на одну в'юшку
GRANT SELECT ON v_MyShelf TO Reader_Guest_User;

-- Відкликаємо роль у гостя
ALTER ROLE Library_Viewer_Role DROP MEMBER Reader_Guest_User;

-- ТЕПЕР: Reader_Guest_User БАЧИТЬ v_MyShelf (персонально), 
-- але НЕ БАЧИТЬ v_BookRatings (права ролі втрачено).
GO

--Перевірка для Гостя (Пункт 7):
EXECUTE AS USER = 'Reader_Guest_User';
-- Це МАЄ працювати (це його персональне право)
SELECT * FROM v_MyShelf; 

-- Це МАЄ видати помилку (бо роль Library_Viewer_Role відкликана)
SELECT * FROM v_BookRatings; 
REVERT;

-- 8. Видалення (Пункт 8)
-- DROP USER IF EXISTS Data_Operator_User;
-- DROP ROLE IF EXISTS Library_Viewer_Role;
-- DROP LOGIN Data_Operator; 
GO

--Перевірка через системні представлення:
--Можна побачити, хто в якій ролі, запустивши цей запит:
--SELECT 
--    DP1.name AS RoleName, 
--    DP2.name AS MemberName  
--FROM sys.database_role_members AS DRM  
--JOIN sys.database_principals AS DP1 ON DRM.role_principal_id = DP1.principal_id  
--JOIN sys.database_principals AS DP2 ON DRM.member_principal_id = DP2.principal_id;



/*
презентація до 10 слайдів

*/





--Перевірка результатів
--SELECT * FROM v_FullLibraryReport ;
