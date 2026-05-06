
	USE master;
	GO

	-- 0. Видаляємо стару базу
	IF EXISTS (SELECT * FROM sys.databases WHERE name = 'MyPersonalLibrary')
	BEGIN
	ALTER DATABASE MyPersonalLibrary SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE MyPersonalLibrary;
	END
	GO

	-- 1. Створюємо базу 
	CREATE DATABASE MyPersonalLibrary;
	GO

	USE MyPersonalLibrary;
	GO

	-- 2. Створення послідовності
	CREATE SEQUENCE BookSequence START WITH 1 INCREMENT BY 1;
	GO

	-- 3. ТАБЛИЦІ-ДОВІДНИКИ
	CREATE TABLE Authors (
	AuthorID INT PRIMARY KEY DEFAULT (NEXT VALUE FOR BookSequence),
	FullName NVARCHAR(255) NOT NULL,
	Country NVARCHAR(100),
	UCR NVARCHAR(100) DEFAULT (SUSER_NAME()),
	DCR DATETIME DEFAULT (GETDATE()),
	ULC NVARCHAR(100),
	DLC DATETIME
	);

	CREATE TABLE Publishers (
	PubID INT PRIMARY KEY DEFAULT (NEXT VALUE FOR BookSequence),
	PubName NVARCHAR(255) NOT NULL UNIQUE,
	UCR NVARCHAR(100) DEFAULT (SUSER_NAME()),
	DCR DATETIME DEFAULT (GETDATE())
	);

	CREATE TABLE Genres (
	GenreID INT PRIMARY KEY DEFAULT (NEXT VALUE FOR BookSequence),
	GenreName NVARCHAR(100) NOT NULL UNIQUE
	);

	CREATE TABLE Tags (
	TagID INT PRIMARY KEY DEFAULT (NEXT VALUE FOR BookSequence),
	TagName NVARCHAR(50) NOT NULL UNIQUE,
	UCR NVARCHAR(100) DEFAULT (SUSER_NAME()),
	DCR DATETIME DEFAULT (GETDATE())
	);

	-- 4. ТАБЛИЦЯ КНИГ
	CREATE TABLE Books (
	BookID INT PRIMARY KEY DEFAULT (NEXT VALUE FOR BookSequence),
	Title NVARCHAR(255) NOT NULL,
	Price DECIMAL(10, 2),
	PurchaseDate DATE,             -- ДАТА ПРИДБАННЯ
	Pages INT,
	BookFormat NVARCHAR(50) DEFAULT N'physical' 
	CONSTRAINT CHK_Format CHECK (BookFormat IN (N'physical', N'Digital (audio)', N'E-book', N'mix')),
	FirstPubYear INT,
	CycleName NVARCHAR(255),
	SourceFrom NVARCHAR(100), 
	IsInLibrary BIT DEFAULT 1, 
	BookStatus NVARCHAR(50) DEFAULT N'нечитана' 
	CONSTRAINT CHK_Status CHECK (BookStatus IN (N'прочитана', N'нечитана', N'в процесі', N'закинуто', N'хочу продати')),
	ReadDate DATE, 
	Rating DECIMAL(3,1) CONSTRAINT CHK_Rating_12 CHECK (Rating BETWEEN 0 AND 12),
	Note NVARCHAR(MAX),
	SalePrice DECIMAL(10, 2), 
	PubID INT CONSTRAINT FK_Books_Publishers FOREIGN KEY REFERENCES Publishers(PubID),
	PreviousBookID INT CONSTRAINT FK_Books_Hierarchy FOREIGN KEY REFERENCES Books(BookID),
	UCR NVARCHAR(100) DEFAULT (SUSER_NAME()),
	DCR DATETIME DEFAULT (GETDATE()),
	ULC NVARCHAR(100),
	DLC DATETIME
	);

	-- 5. ТАБЛИЦІ-ЗВ'ЯЗКИ
	CREATE TABLE BookAuthors (BookID INT FOREIGN KEY REFERENCES Books(BookID) ON DELETE CASCADE, AuthorID INT FOREIGN KEY REFERENCES Authors(AuthorID) ON DELETE CASCADE, PRIMARY KEY (BookID, AuthorID));
	CREATE TABLE BookGenres (BookID INT FOREIGN KEY REFERENCES Books(BookID) ON DELETE CASCADE, GenreID INT FOREIGN KEY REFERENCES Genres(GenreID) ON DELETE CASCADE, PRIMARY KEY (BookID, GenreID));
	CREATE TABLE BookTags (BookID INT FOREIGN KEY REFERENCES Books(BookID) ON DELETE CASCADE, TagID INT FOREIGN KEY REFERENCES Tags(TagID) ON DELETE CASCADE, PRIMARY KEY (BookID, TagID));
	GO

	-- 6. ПРЕДСТАВЛЕННЯ (VIEWS)
	CREATE VIEW v_MyShelf AS
    SELECT 
    b.Title, 
    ISNULL(STRING_AGG(a.FullName, ', '), N'Не вказано') AS Authors, 
    b.BookFormat, 
    b.Pages, 
    b.BookStatus,
    ISNULL(CONVERT(NVARCHAR, b.PurchaseDate, 104), N'Не вказано') AS PurchaseDate -- Додано дату придбання
    FROM Books b
    LEFT JOIN BookAuthors ba ON b.BookID = ba.BookID
    LEFT JOIN Authors a ON ba.AuthorID = a.AuthorID
    WHERE b.IsInLibrary = 1 AND b.BookStatus != N'хочу продати'
    GROUP BY b.BookID, b.Title, b.BookFormat, b.Pages, b.BookStatus, b.PurchaseDate;
    GO



	-- v_BookRatings 
	CREATE VIEW v_BookRatings AS
	SELECT 
	b.Title AS [Назва],
	(SELECT STRING_AGG(a.FullName, ', ') FROM BookAuthors ba JOIN Authors a ON ba.AuthorID = a.AuthorID WHERE ba.BookID = b.BookID) AS [Автор],
	CAST(b.Rating AS NVARCHAR(4)) + '/10' AS [Оцінка],
	(SELECT STRING_AGG(g.GenreName, ', ') FROM BookGenres bg JOIN Genres g ON bg.GenreID = g.GenreID WHERE bg.BookID = b.BookID) AS [Жанр],
	(SELECT STRING_AGG(t.TagName, ', ') FROM BookTags bt JOIN Tags t ON bt.TagID = t.TagID WHERE bt.BookID = b.BookID) AS [Теги],
	b.Pages AS [Кількість сторінок],
	ISNULL(b.CycleName, N'-') AS [Цикл],
	ISNULL(CONVERT(NVARCHAR, b.ReadDate, 104), N'Ще не прочитано') AS [Дата закінчення],
	b.BookFormat AS [Формат],
	ISNULL(b.Note, N'') AS [Примітка]
	FROM Books b;
	GO


	-- Розширене представлення з усіма наявними даними (без дублювання рядків)
CREATE OR ALTER VIEW v_FullLibraryReport AS
SELECT 
    b.BookID,
    b.Title AS [Назва книги],
    -- Автори
    ISNULL((
        SELECT STRING_AGG(CAST(a.FullName AS NVARCHAR(MAX)), '; ')
        FROM BookAuthors ba
        JOIN Authors a ON ba.AuthorID = a.AuthorID
        WHERE ba.BookID = b.BookID
    ), N'Не вказано') AS [Автори],
    -- Жанри
    ISNULL((
        SELECT STRING_AGG(CAST(g.GenreName AS NVARCHAR(MAX)), ', ')
        FROM BookGenres bg
        JOIN Genres g ON bg.GenreID = g.GenreID 
        WHERE bg.BookID = b.BookID
    ), N'-') AS [Жанри],
    -- Теги
    ISNULL((
        SELECT STRING_AGG(CAST(t.TagName AS NVARCHAR(MAX)), ', ')
        FROM BookTags bt 
        JOIN Tags t ON bt.TagID = t.TagID 
        WHERE bt.BookID = b.BookID
    ), N'-') AS [Теги],
    CAST(b.Rating AS NVARCHAR(10)) + '/12' AS [Оцінка],
    ISNULL(CONVERT(NVARCHAR, b.ReadDate, 104), N'Ще не прочитано') AS [Дата прочитання],
    ISNULL(CONVERT(NVARCHAR, b.PurchaseDate, 104), N'Не вказано') AS [Дата придбання],
    b.FirstPubYear AS [Рік видання],
    -- Країни походження
    ISNULL((
        SELECT STRING_AGG(CAST(ISNULL(a.Country, N'н/д') AS NVARCHAR(MAX)), '; ')
        FROM BookAuthors ba
        JOIN Authors a ON ba.AuthorID = a.AuthorID
        WHERE ba.BookID = b.BookID
    ), N'-') AS [Країни],
    p.PubName AS [Видавництво],
    b.CycleName AS [Цикл/Серія],
    b.SourceFrom AS [звідки],
    b.Pages AS [Сторінки],
    b.Price AS [Ціна покупки],
    b.SalePrice AS [Ціна продажу],
    CASE WHEN b.IsInLibrary = 1 THEN N'Так' ELSE N'Ні' END AS [бібліотека],
    b.BookStatus AS [Статус],
    b.BookFormat AS [Формат],
    b.Note AS [Примітка],
    -- ПОЛЯ АУДИТУ (Системні дані)
    b.UCR AS [Створив (користувач)],
    CONVERT(NVARCHAR, b.DCR, 104) + ' ' + CONVERT(NVARCHAR, b.DCR, 108) AS [Дата створення],
    ISNULL(b.ULC, N'-') AS [Змінив (користувач)],
    ISNULL(CONVERT(NVARCHAR, b.DLC, 104) + ' ' + CONVERT(NVARCHAR, b.DLC, 108), N'-') AS [Дата останньої зміни]
FROM Books b
LEFT JOIN Publishers p ON b.PubID = p.PubID;
GO


-- Створюємо універсальну процедуру для видалення будь-якої книги за назвою
CREATE OR ALTER PROCEDURE sp_DeleteBookByTitle
    @Title NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @BID INT;

    -- Знаходимо ID книги
    SELECT @BID = BookID FROM Books WHERE Title = @Title;

    IF @BID IS NOT NULL
    BEGIN
        -- Видаляємо всі зв'язки автоматично
        DELETE FROM BookAuthors WHERE BookID = @BID;
        DELETE FROM BookGenres  WHERE BookID = @BID;
        DELETE FROM BookTags    WHERE BookID = @BID;
        
        -- Видаляємо саму книгу
        DELETE FROM Books WHERE BookID = @BID;

        PRINT N'Книгу "' + @Title + N'" видалено успішно.';
    END
    ELSE
    BEGIN
        PRINT N'Помилка: Книгу з назвою "' + @Title + N'" не знайдено.';
    END
END;
GO


-- СТВОРЮЄМО ПОВНУ (Для всіх полів)
CREATE OR ALTER PROCEDURE sp_AddFullBook
    @Title NVARCHAR(255),
    @Price DECIMAL(10,2) = NULL,
    @PurchaseDate DATE = NULL,
    @Pages INT = NULL,
    @Format NVARCHAR(50) = N'physical',
    @Year INT = NULL,
    @Cycle NVARCHAR(255) = NULL,
    @Source NVARCHAR(100) = NULL,
    @Status NVARCHAR(50) = N'нечитана',
    @ReadDate DATE = NULL,
    @Rating DECIMAL(3,1) = NULL,
    @Publisher NVARCHAR(255) = NULL,
    @SalePrice DECIMAL(10, 2) = NULL,      -- ЦІНА ПРОДАЖУ
    @IsInLibrary BIT = 1,                 -- В БІБЛІОТЕЦІ (0 або 1)
    @PreviousBookTitle NVARCHAR(255) = NULL, -- ДЛЯ ІЄРАРХІЇ (Назва попередньої книги)
    @Note NVARCHAR(MAX) = NULL,
    @Authors NVARCHAR(MAX) = NULL, -- Список імен через кому
    @Genres NVARCHAR(MAX) = NULL,  -- Список через кому
    @Tags NVARCHAR(MAX) = NULL     -- Список через кому
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @BID INT, @PID INT, @PrevBID INT;

    -- А. Обробка Видавництва
    IF @Publisher IS NOT NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM Publishers WHERE PubName = @Publisher)
            INSERT INTO Publishers (PubName) VALUES (@Publisher);
        SELECT @PID = PubID FROM Publishers WHERE PubName = @Publisher;
    END

    -- Б. Обробка Ієрархії (знаходимо ID попередньої книги за назвою)
    IF @PreviousBookTitle IS NOT NULL
        SELECT @PrevBID = BookID FROM Books WHERE Title = @PreviousBookTitle;

    -- В. Вставка або Оновлення книги
    IF NOT EXISTS (SELECT 1 FROM Books WHERE Title = @Title)
    BEGIN
        INSERT INTO Books (
            Title, Price, PurchaseDate, Pages, BookFormat, FirstPubYear, 
            CycleName, SourceFrom, BookStatus, ReadDate, Rating, 
            PubID, SalePrice, IsInLibrary, PreviousBookID, Note
        )
        VALUES (
            @Title, @Price, @PurchaseDate, @Pages, @Format, @Year, 
            @Cycle, @Source, @Status, @ReadDate, @Rating, 
            @PID, @SalePrice, @IsInLibrary, @PrevBID, @Note
        );
    END
    ELSE
    BEGIN
        UPDATE Books SET 
            Price = @Price, 
            PurchaseDate = @PurchaseDate, 
            Pages = @Pages, 
            BookFormat = @Format, 
            FirstPubYear = @Year, 
            CycleName = @Cycle, 
            SourceFrom = @Source, 
            BookStatus = @Status, 
            ReadDate = @ReadDate, 
            Rating = @Rating, 
            PubID = @PID, 
            SalePrice = @SalePrice, 
            IsInLibrary = @IsInLibrary, 
            PreviousBookID = @PrevBID, 
            Note = @Note,
            ULC = SUSER_NAME(),
            DLC = GETDATE()
        WHERE Title = @Title;
    END

    SELECT @BID = BookID FROM Books WHERE Title = @Title;

    -- Г. Обробка АВТОРІВ
    IF @Authors IS NOT NULL
    BEGIN
        INSERT INTO Authors (FullName)
        SELECT DISTINCT TRIM(value) FROM STRING_SPLIT(@Authors, ',')
        WHERE TRIM(value) NOT IN (SELECT FullName FROM Authors);

        INSERT INTO BookAuthors (BookID, AuthorID)
        SELECT @BID, a.AuthorID FROM Authors a
        WHERE a.FullName IN (SELECT DISTINCT TRIM(value) FROM STRING_SPLIT(@Authors, ','))
        AND NOT EXISTS (SELECT 1 FROM BookAuthors WHERE BookID = @BID AND AuthorID = a.AuthorID);
    END

    -- Д. Обробка ЖАНРІВ
    IF @Genres IS NOT NULL
    BEGIN
        INSERT INTO Genres (GenreName)
        SELECT DISTINCT TRIM(value) FROM STRING_SPLIT(@Genres, ',')
        WHERE TRIM(value) NOT IN (SELECT GenreName FROM Genres);

        INSERT INTO BookGenres (BookID, GenreID)
        SELECT @BID, g.GenreID FROM Genres g
        WHERE g.GenreName IN (SELECT DISTINCT TRIM(value) FROM STRING_SPLIT(@Genres, ','))
        AND NOT EXISTS (SELECT 1 FROM BookGenres WHERE BookID = @BID AND GenreID = g.GenreID);
    END

    -- Е. Обробка ТЕГІВ
    IF @Tags IS NOT NULL
    BEGIN
        INSERT INTO Tags (TagName)
        SELECT DISTINCT TRIM(value) FROM STRING_SPLIT(@Tags, ',')
        WHERE TRIM(value) NOT IN (SELECT TagName FROM Tags);

        INSERT INTO BookTags (BookID, TagID)
        SELECT @BID, t.TagID FROM Tags t
        WHERE t.TagName IN (SELECT DISTINCT TRIM(value) FROM STRING_SPLIT(@Tags, ','))
        AND NOT EXISTS (SELECT 1 FROM BookTags WHERE BookID = @BID AND TagID = t.TagID);
    END

    PRINT N'Книгу "' + @Title + N'" оновлено.';
END;
GO