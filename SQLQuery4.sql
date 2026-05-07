USE MyPersonalLibrary;
GO

-- 1. Процедура розрахунку цінності для ОДНІЄЇ книги
CREATE OR ALTER PROCEDURE sp_CalculateBookValue
    @TargetBookID INT
AS
BEGIN
    DECLARE @Rating DECIMAL(3,1), @Pages INT, @Status NVARCHAR(50), @InLib BIT;
    DECLARE @Value DECIMAL(5,2);
    DECLARE @NoteContent NVARCHAR(MAX);
    DECLARE @ValueMarker NVARCHAR(50) = N' [Цінність: %]'; -- Маркер для пошуку

    -- Отримуємо вхідні дані для формули
    SELECT 
        @Rating = ISNULL(Rating, 0), 
        @Pages = ISNULL(Pages, 0), 
        @Status = BookStatus, 
        @InLib = IsInLibrary,
        @NoteContent = ISNULL(Note, N'')
    FROM Books WHERE BookID = @TargetBookID;

    -- АЛГОРИТМ:
    SET @Value = (@Rating * 2) + (@Pages / 100.0);
    IF (@Status = N'прочитана') SET @Value = @Value + 3;
    IF (@InLib = 1) SET @Value = @Value + 2;

    -- ОЧИЩЕННЯ Note від старої цінності (якщо вона там є)
    -- Видаляємо все, що знаходиться між квадратними дужками " [Цінність: ...]"
    IF @NoteContent LIKE N'% [Цінність: %]%'
    BEGIN
        -- Знаходимо початок маркера і обрізаємо Note до нього
        DECLARE @Pos INT = CHARINDEX(N' [Цінність:', @NoteContent);
        SET @NoteContent = RTRIM(LEFT(@NoteContent, @Pos - 1));
    END

    -- ЗАПИС нового результату в Note
    UPDATE Books
    SET Note = CASE 
        WHEN LEN(@NoteContent) > 0 THEN @NoteContent + N' [Цінність: ' + CAST(@Value AS NVARCHAR) + N']'
        ELSE N'[Цінність: ' + CAST(@Value AS NVARCHAR) + N']'
    END
    WHERE BookID = @TargetBookID;

    PRINT N'Книга ID ' + CAST(@TargetBookID AS NVARCHAR) + N': нова цінність ' + CAST(@Value AS NVARCHAR);
END;
GO

-- 2. Головна процедура (виклик для всіх за вказаний період)
CREATE OR ALTER PROCEDURE sp_ProcessBooksByPeriod
    @YearFrom INT,
    @YearTo INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @BID INT;

    -- Курсор для перебору книг за вказаний період років видання
    DECLARE book_cursor CURSOR FOR 
    SELECT BookID FROM Books 
    WHERE FirstPubYear BETWEEN @YearFrom AND @YearTo;

    OPEN book_cursor;
    FETCH NEXT FROM book_cursor INTO @BID;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC sp_CalculateBookValue @BID;
        FETCH NEXT FROM book_cursor INTO @BID;
    END;

    CLOSE book_cursor;
    DEALLOCATE book_cursor;
    
    PRINT N'Обробку завершено.';
END;
GO

-- Оновимо цінність для всіх книг, виданих з 2000 по 2026 рік
EXEC sp_ProcessBooksByPeriod 2000, 2026;

-- Дивимось результат
SELECT Title, Note FROM Books;