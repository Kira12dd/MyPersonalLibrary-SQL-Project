

USE MyPersonalLibrary;
GO

-----------------------------------------------------------------------------
-- 1. SELECT на базі однієї таблиці (Сортування, OR, AND)
-- ПРИЗНАЧЕННЯ: Знайти дорогі книги (>300 грн) або книги з високим рейтингом (>10),
-- які при цьому мають більше 400 сторінок.
-----------------------------------------------------------------------------
SELECT Title, Price, Rating, Pages
FROM Books
WHERE (ISNULL(Price, 0) > 300 OR ISNULL(Rating, 0) > 10) AND ISNULL(Pages, 0) > 400
ORDER BY Rating DESC, Price ASC;
GO

-----------------------------------------------------------------------------
-- 2. SELECT з виводом обчислюваних полів (ОНОВЛЕНО)
-- ПРИЗНАЧЕННЯ: Розрахувати вартість однієї сторінки книги (Ціна/Сторінки) 
-- та визначити статус "Стара/Нова" залежно від року видання.
-----------------------------------------------------------------------------
SELECT 
    Title, 
    Price AS [Загальна ціна],
    Pages AS [К-ть сторінок],
    CAST(ISNULL(Price, 0) / NULLIF(ISNULL(Pages, 0), 0) AS DECIMAL(10,2)) AS [Вартість 1 сторінки],
    CASE 
        WHEN FirstPubYear < 2000 THEN N'Ретро/Класика'
        ELSE N'Сучасне видання'
    END AS [Категорія за віком]
FROM Books
WHERE Pages > 0;
GO

-----------------------------------------------------------------------------
-- 3. SELECT на базі кількох таблиць (Inner Join, Сортування, Умови)
-- ПРИЗНАЧЕННЯ: Вивести назви книг разом з іменами їхніх авторів та видавництвами.
-----------------------------------------------------------------------------
SELECT 
    b.Title AS [Книга], 
    a.FullName AS [Автор], 
    p.PubName AS [Видавництво]
FROM Books b
JOIN BookAuthors ba ON b.BookID = ba.BookID
JOIN Authors a ON ba.AuthorID = a.AuthorID
JOIN Publishers p ON b.PubID = p.PubID
WHERE ISNULL(a.Country, N'') = N'США' OR p.PubName LIKE N'%КСД%'
ORDER BY b.Title;
GO

-----------------------------------------------------------------------------
-- 4. SELECT з типом поєднання Outer Join
-- ПРИЗНАЧЕННЯ: Вивести всі видавництва, навіть ті, для яких у базі ще немає книг.
-----------------------------------------------------------------------------
SELECT 
    p.PubName, 
    COUNT(b.BookID) AS [Кількість книг у базі]
FROM Publishers p
LEFT OUTER JOIN Books b ON p.PubID = b.PubID
GROUP BY p.PubName;
GO

-----------------------------------------------------------------------------
-- 5. SELECT з використанням Like, Between, In, Exists
-- ПРИЗНАЧЕННЯ: Пошук книг за складними критеріями.
-----------------------------------------------------------------------------
SELECT Title, FirstPubYear, BookFormat
FROM Books b
WHERE Title LIKE N'%Зозуля%' 
  AND ISNULL(FirstPubYear, 0) BETWEEN 2000 AND 2025 
  AND BookFormat IN (N'physical', N'Digital (audio)') 
  AND EXISTS (SELECT 1 FROM BookAuthors ba WHERE ba.BookID = b.BookID);
GO

-----------------------------------------------------------------------------
-- 6. SELECT з використанням підсумовування та групування
-- ПРИЗНАЧЕННЯ: Отримати статистику: загальна кількість сторінок та середня ціна за статусом.
-----------------------------------------------------------------------------
SELECT 
    BookStatus, 
    COUNT(*) AS [Кількість],
    SUM(ISNULL(Pages, 0)) AS [Всього сторінок],
    AVG(ISNULL(Price, 0)) AS [Середня ціна покупки]
FROM Books
GROUP BY BookStatus
HAVING COUNT(*) > 0;
GO

-----------------------------------------------------------------------------
-- 7. SELECT з використанням під-запитів в частині WHERE
-- ПРИЗНАЧЕННЯ: Вибрати книги авторів, які написали більше 1 книги в нашій базі.
---------------------------------------------------------------------------
SELECT 
    b.Title AS [Книга], 
    a.FullName AS [Автор]
FROM Books b
JOIN BookAuthors ba ON b.BookID = ba.BookID
JOIN Authors a ON ba.AuthorID = a.AuthorID
WHERE b.BookID IN (
    SELECT BookID 
    FROM BookAuthors 
    WHERE AuthorID IN (
        SELECT AuthorID FROM BookAuthors GROUP BY AuthorID HAVING COUNT(*) > 1
    )
);
GO

-----------------------------------------------------------------------------
-- 8. SELECT з використанням під-запитів в частині FROM
-- ПРИЗНАЧЕННЯ: Знайти книги, рейтинг яких вищий за середній по всій бібліотеці.
-----------------------------------------------------------------------------
SELECT T.Title, T.Rating
FROM (SELECT Title, ISNULL(Rating, 0) AS Rating FROM Books) AS T
WHERE T.Rating > (SELECT AVG(ISNULL(Rating, 0)) FROM Books);
GO

-----------------------------------------------------------------------------
-- 9. Ієрархічний SELECT запит (Recursive CTE)
-- ПРИЗНАЧЕННЯ: Вивести ланцюжок серії книг (що за чим читати).
---------------------------------------------------------------------------

WITH BookSeries AS (
    -- Якірна частина: вибираємо перші книги у серіях (або поодинокі книги)
    SELECT BookID, Title, PreviousBookID, CycleName, 1 AS Level,
           CAST(Title AS NVARCHAR(MAX)) AS FullPath
    FROM Books 
    WHERE PreviousBookID IS NULL
    
    UNION ALL
    
    -- Рекурсивна частина: приєднуємо наступні книги, посилаючись на попередній рівень
    SELECT b.BookID, b.Title, b.PreviousBookID, b.CycleName, bs.Level + 1,
           bs.FullPath + N' > ' + b.Title
    FROM Books b
    INNER JOIN BookSeries bs ON b.PreviousBookID = bs.BookID
)
SELECT 
    ISNULL(CycleName, N'Поза циклами') AS [Серія],
    REPLICATE(N'   ', Level - 1) + 
    CASE WHEN Level > 1 THEN N'╚══ > ' ELSE N'' END + Title AS [Порядок читання],
    Level AS [Рівень у серії]
FROM BookSeries
ORDER BY [Серія], Level;
GO

-----------------------------------------------------------------------------
-- 10. SELECT запит типу CrossTab (PIVOT)
-- ПРИЗНАЧЕННЯ: Порахувати кількість книг кожного формату для кожного статусу.
-----------------------------------------------------------------------------
SELECT BookStatus, [physical], [Digital (audio)], [E-book]
FROM (
    SELECT BookStatus, BookFormat, BookID FROM Books
) AS SourceTable
PIVOT (
    COUNT(BookID) 
    FOR BookFormat IN ([physical], [Digital (audio)], [E-book])
) AS PivotTable;
GO

-----------------------------------------------------------------------------
-- 11. UPDATE на базі однієї таблиці
-- ПРИЗНАЧЕННЯ: Підняти ціну продажу на 10%. 
-----------------------------------------------------------------------------
UPDATE Books
SET SalePrice = ISNULL(Price, 0) * 1.1,
    ULC = SUSER_NAME(),
    DLC = GETDATE()
WHERE ISNULL(Rating, 0) >= 10;

-- ПЕРЕВІРКА РЕЗУЛЬТАТУ 
SELECT Title, Price, SalePrice, Rating 
FROM Books 
WHERE ISNULL(Rating, 0) >= 10;
GO

-----------------------------------------------------------------------------
-- 12. UPDATE на базі кількох таблиць (через JOIN)
-- ПРИЗНАЧЕННЯ: Встановити статус "хочу продати" для книг певного жанру.
-----------------------------------------------------------------------------
UPDATE b
SET b.BookStatus = N'хочу продати'
FROM Books b
JOIN BookGenres bg ON b.BookID = bg.BookID
JOIN Genres g ON bg.GenreID = g.GenreID
WHERE g.GenreName = N'Детектив';
GO

-- ПЕРЕВІРКА РЕЗУЛЬТАТУ
SELECT b.Title, b.BookStatus, g.GenreName
FROM Books b
JOIN BookGenres bg ON b.BookID = bg.BookID
JOIN Genres g ON bg.GenreID = g.GenreID
WHERE g.GenreName = N'Детектив';
GO

-----------------------------------------------------------------------------
-- 13. Append (INSERT) з явно вказаними значеннями
-----------------------------------------------------------------------------
INSERT INTO Genres (GenreName) VALUES (N'Наукова фантастика');
GO
--ПЕРЕВІРКА: пошук доданого жанру
SELECT * FROM Genres WHERE GenreName = N'Наукова фантастика';
GO

-----------------------------------------------------------------------------
-- 14. Append (INSERT) з інших таблиць
-- ПРИЗНАЧЕННЯ: Створення таблиці-архіву та автоматичне копіювання до неї всіх книг зі статусом "прочитана".
-----------------------------------------------------------------------------
SELECT * INTO ReadBooksArchive
FROM Books
WHERE BookStatus = N'прочитана';

-- Перевірка результату копіювання
SELECT * FROM ReadBooksArchive;
GO

-----------------------------------------------------------------------------
-- 15. DELETE для видалення вибраних записів
-----------------------------------------------------------------------------
DELETE FROM Books 
WHERE ISNULL(Rating, 0) = 0 AND IsInLibrary = 0;
GO
-- Перевірка: скільки книг залишилося в базі
SELECT COUNT(*) AS [Книг після видалення] FROM Books;

-----------------------------------------------------------------------------
-- 16. СКЛАДНИЙ ЗАПИТ №1 (Агрегація + JOIN + Subquery + Calculated Field)
-- ПРИЗНАЧЕННЯ: Аналіз вартості бібліотеки по авторах з урахуванням NULL цін.
-----------------------------------------------------------------------------
SELECT 
    a.FullName,
    SUM(ISNULL(b.Price, 0)) AS [Загальна вартість книг автора],
    COUNT(b.BookID) AS [Кількість книг],
    CAST(SUM(ISNULL(b.Price, 0)) * 100.0 / (SELECT SUM(ISNULL(Price, 0)) FROM Books) AS DECIMAL(5,2)) AS [% від вартості бібліотеки]
FROM Authors a
JOIN BookAuthors ba ON a.AuthorID = ba.AuthorID
JOIN Books b ON ba.BookID = b.BookID
GROUP BY a.FullName
HAVING SUM(ISNULL(b.Price, 0)) > 200
ORDER BY [Загальна вартість книг автора] DESC;
GO

-----------------------------------------------------------------------------
-- 17. СКЛАДНИЙ ЗАПИТ №2 (CTE + Windows Function + Outer Join)
-- ПРИЗНАЧЕННЯ: Ранжування за рейтингом з обробкою NULL значень.
-----------------------------------------------------------------------------
WITH PubStats AS (
    SELECT 
        p.PubName,
        b.Title,
        ISNULL(b.Rating, 0) AS Rating,
        AVG(ISNULL(b.Rating, 0)) OVER(PARTITION BY p.PubName) AS [Середній рейтинг видавництва],
        RANK() OVER(PARTITION BY p.PubName ORDER BY ISNULL(b.Rating, 0) DESC) AS [Ранг у видавництві]
    FROM Publishers p
    LEFT JOIN Books b ON p.PubID = b.PubID
)
SELECT *, (Rating - [Середній рейтинг видавництва]) AS [Відхилення від середнього]
FROM PubStats
WHERE Title IS NOT NULL;
GO
