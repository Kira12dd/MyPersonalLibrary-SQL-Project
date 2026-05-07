USE MyPersonalLibrary;
GO

-- 1. НАПОВНЕННЯ ДОВІДНИКІВ
INSERT INTO Authors (FullName) VALUES 
(N'Брендон Сандерсон'), 
(N'Агата Крісті'), 
(N'Террі Пратчетт'), 
(N'Голлі Джексон');

INSERT INTO Publishers (PubName) VALUES 
(N'КСД (Клуб Сімейного Дозвілля)'), 
(N'Видавництво Старого Лева'), 
(N'readberry');

-- 2. ДОДАВАННЯ КНИГ 
INSERT INTO Books (Title, Pages, Price, BookFormat, FirstPubYear, CycleName, Rating, BookStatus, ReadDate, Note, PubID, IsInLibrary) 
VALUES 
-- Шлях королів
(N'Шлях королів', 1152, 450.00, N'physical', 2010, N'Хроніки Буресвітла (10)', 11.0, N'прочитана', 
 '2024-01-13', N'Вав', (SELECT PubID FROM Publishers WHERE PubName = N'КСД (Клуб Сімейного Дозвілля)'), 1),

-- І не лишилось жодного 
(N'І не лишилось жодного', 288, 230.00, N'physical', 1939, NULL, 9.0, N'прочитана', 
 '2023-08-20', N'Empty', (SELECT PubID FROM Publishers WHERE PubName = N'КСД (Клуб Сімейного Дозвілля)'), 1),

-- Правда 
(N'Правда', 456, NULL, N'physical', 2000, NULL, 10.0, N'прочитана', 
 '2024-05-21', N'Дискосвіт', (SELECT PubID FROM Publishers WHERE PubName = N'Видавництво Старого Лева'), 1),

-- Морт 
(N'Морт', 304, 230.00, N'physical', 1987, N'Смерть (5)', 10.0, N'прочитана', 
 '2023-12-14', N'Empty', (SELECT PubID FROM Publishers WHERE PubName = N'Видавництво Старого Лева'), 1),

-- Виживуть п'ятеро 
(N'Виживуть п''ятеро', 448, NULL, N'Digital (audio)', 2022, NULL, 8.5, N'прочитана', 
 NULL, N'Сюжетна лінія завершена, але кінець відкритий', (SELECT PubID FROM Publishers WHERE PubName = N'readberry'), 0);

-- 3. СТВОРЕННЯ ЗВ'ЯЗКІВ
-- Автори
INSERT INTO BookAuthors (BookID, AuthorID) SELECT b.BookID, a.AuthorID FROM Books b, Authors a WHERE b.Title = N'Шлях королів' AND a.FullName = N'Брендон Сандерсон';
INSERT INTO BookAuthors (BookID, AuthorID) SELECT b.BookID, a.AuthorID FROM Books b, Authors a WHERE b.Title = N'І не лишилось жодного' AND a.FullName = N'Агата Крісті';
INSERT INTO BookAuthors (BookID, AuthorID) SELECT b.BookID, a.AuthorID FROM Books b, Authors a WHERE b.Title IN (N'Правда', N'Морт') AND a.FullName = N'Террі Пратчетт';
INSERT INTO BookAuthors (BookID, AuthorID) SELECT b.BookID, a.AuthorID FROM Books b, Authors a WHERE b.Title = N'Виживуть п''ятеро' AND a.FullName = N'Голлі Джексон';

-- Теги (приклад для "Шлях королів")
INSERT INTO BookTags (BookID, TagID) 
SELECT b.BookID, t.TagID FROM Books b, Tags t 
WHERE b.Title = N'Шлях королів' AND t.TagName IN (N'Епічне фентезі', N'Пригоди', N'Помста', N'Меч', N'Боротьба за владу', N'Магія', N'Смерть', N'Війна');

GO



-- 1. НАПОВНЕННЯ ДОВІДНИКІВ (Автори, Видавництва, Жанри, Теги)
INSERT INTO Authors (FullName) VALUES 
(N'Роберт Ґалбрейт (Дж. К. Роулінг)'), 
(N'Лі Бардуґо'), 
(N'Юлія Нагорнюк');

INSERT INTO Publishers (PubName) VALUES 
(N'Bookchef'), 
(N'КМ-букс'), 
(N'Віват'), 
(N'Ще одну сторінку');

INSERT INTO Genres (GenreName) VALUES 
(N'Детектив'), (N'Фентезі'), (N'Повсякденність');

INSERT INTO Tags (TagName) VALUES 
(N'Пригоди'), (N'Убивця'), (N'Кримінал'), (N'дарк академія'), (N'Магія'), 
(N'привиди'), (N'Химерність'), (N'Трагедія'), (N'Академія'), 
(N'Різні часові проміжки'), (N'Відьми'), (N'Cozy(pleasant)'), 
(N'Гумор'), (N'Історія кохання');

-- 2. ДОДАВАННЯ КНИГ
INSERT INTO Books (Title, Pages, Price, BookFormat, FirstPubYear, CycleName, Rating, BookStatus, ReadDate, Note, PubID, IsInLibrary) 
VALUES 
-- Кувала зозуля
(N'Кувала зозуля', 512, 150.00, N'Digital (audio)', 2013, N'Корморан Страйк(10)', 7.5, N'прочитана', 
'2024-03-05', N'Empty', (SELECT PubID FROM Publishers WHERE PubName = N'Bookchef'), 0),

-- Шовкопряд
(N'Шовкопряд', 544, 150.00, N'Digital (audio)', 2014, N'Корморан Страйк(10)', 7.5, N'прочитана', 
'2024-07-01', N'Empty', (SELECT PubID FROM Publishers WHERE PubName = N'КМ-букс'), 0),

-- Дев’ятий Дім
(N'Дев’ятий Дім', 524, 360.00, N'physical', 2019, N'Алекс Стерн', 9.0, N'прочитана', 
'2025-01-27', N'подарунок на 18, від батьків', (SELECT PubID FROM Publishers WHERE PubName = N'Віват'), 1),

-- Діва, матір і третя
(N'Діва, матір і третя', 414, 45.00, N'physical', 2024, NULL, 8.0, N'прочитана', 
'2025-03-27', N'прикольний світ, не зовсім мій жанр', (SELECT PubID FROM Publishers WHERE PubName = N'Ще одну сторінку'), 0);

-- 3. СТВОРЕННЯ ЗВ'ЯЗКІВ (Автори, Жанри, Теги)

-- Автори
INSERT INTO BookAuthors (BookID, AuthorID) SELECT b.BookID, a.AuthorID FROM Books b, Authors a WHERE b.Title IN (N'Кувала зозуля', N'Шовкопряд') AND a.FullName = N'Роберт Ґалбрейт (Дж. К. Роулінг)';
INSERT INTO BookAuthors (BookID, AuthorID) SELECT b.BookID, a.AuthorID FROM Books b, Authors a WHERE b.Title = N'Дев’ятий Дім' AND a.FullName = N'Лі Бардуґо';
INSERT INTO BookAuthors (BookID, AuthorID) SELECT b.BookID, a.AuthorID FROM Books b, Authors a WHERE b.Title = N'Діва, матір і третя' AND a.FullName = N'Юлія Нагорнюк';

-- Жанри
INSERT INTO BookGenres (BookID, GenreID) SELECT b.BookID, g.GenreID FROM Books b, Genres g WHERE b.Title IN (N'Кувала зозуля', N'Шовкопряд') AND g.GenreName = N'Детектив';
INSERT INTO BookGenres (BookID, GenreID) SELECT b.BookID, g.GenreID FROM Books b, Genres g WHERE b.Title = N'Дев’ятий Дім' AND g.GenreName = N'Фентезі';
INSERT INTO BookGenres (BookID, GenreID) SELECT b.BookID, g.GenreID FROM Books b, Genres g WHERE b.Title = N'Діва, матір і третя' AND g.GenreName IN (N'Повсякденність', N'Фентезі');

-- Теги
INSERT INTO BookTags (BookID, TagID) SELECT b.BookID, t.TagID FROM Books b, Tags t WHERE b.Title = N'Кувала зозуля' AND t.TagName IN (N'Пригоди', N'Убивця', N'Кримінал');
INSERT INTO BookTags (BookID, TagID) SELECT b.BookID, t.TagID FROM Books b, Tags t WHERE b.Title = N'Шовкопряд' AND t.TagName = N'Убивця';
INSERT INTO BookTags (BookID, TagID) SELECT b.BookID, t.TagID FROM Books b, Tags t WHERE b.Title = N'Дев’ятий Дім' AND t.TagName IN (N'дарк академія', N'Магія', N'привиди', N'Убивця', N'Химерність', N'Трагедія', N'Академія', N'Кримінал', N'Різні часові проміжки');
INSERT INTO BookTags (BookID, TagID) SELECT b.BookID, t.TagID FROM Books b, Tags t WHERE b.Title = N'Діва, матір і третя' AND t.TagName IN (N'Відьми', N'Пригоди', N'Cozy(pleasant)', N'Магія', N'Гумор', N'Історія кохання');

GO

--  ДОДАЄМО ЖАНРИ ТА ТЕГИ, ЯКИХ МОЖЕ НЕ ВИСТАЧАТИ В ДОВІДНИКАХ
INSERT INTO Genres (GenreName) 
SELECT Name FROM (VALUES (N'Фентезі'), (N'Детектив'), (N'Трилер'), (N'Повсякденність')) AS T(Name)
WHERE NOT EXISTS (SELECT 1 FROM Genres WHERE GenreName = T.Name);

INSERT INTO Tags (TagName) 
SELECT Name FROM (VALUES 
(N'Епічне фентезі'), (N'Пригоди'), (N'Помста'), (N'Меч'), (N'Боротьба за владу'), (N'Магія'), (N'Смерть'), (N'Війна'),
(N'Герметичний детектив'), (N'Дискосвіт'), (N'Газета'), (N'Про життя'), (N'Убивця'), (N'психологічний трилер'), (N'Відкритий фінал'),
(N'Кримінал'), (N'дарк академія'), (N'привиди'), (N'Химерність'), (N'Трагедія'), (N'Академія'), (N'Різні часові проміжки'),
(N'Відьми'), (N'Cozy(pleasant)'), (N'Гумор'), (N'Історія кохання')) AS T(Name)
WHERE NOT EXISTS (SELECT 1 FROM Tags WHERE TagName = T.Name);

--  ЗАПОВНЮЄМО ЖАНРИ 
INSERT INTO BookGenres (BookID, GenreID)
SELECT b.BookID, g.GenreID FROM Books b, Genres g 
WHERE b.Title = N'Шлях королів' AND g.GenreName = N'Фентезі'
AND NOT EXISTS (SELECT 1 FROM BookGenres WHERE BookID = b.BookID AND GenreID = g.GenreID);

INSERT INTO BookGenres (BookID, GenreID)
SELECT b.BookID, g.GenreID FROM Books b, Genres g 
WHERE b.Title = N'І не лишилось жодного' AND g.GenreName = N'Детектив'
AND NOT EXISTS (SELECT 1 FROM BookGenres WHERE BookID = b.BookID AND GenreID = g.GenreID);

INSERT INTO BookGenres (BookID, GenreID)
SELECT b.BookID, g.GenreID FROM Books b, Genres g 
WHERE b.Title IN (N'Правда', N'Морт') AND g.GenreName = N'Фентезі'
AND NOT EXISTS (SELECT 1 FROM BookGenres WHERE BookID = b.BookID AND GenreID = g.GenreID);

INSERT INTO BookGenres (BookID, GenreID)
SELECT b.BookID, g.GenreID FROM Books b, Genres g 
WHERE b.Title = N'Виживуть п''ятеро' AND g.GenreName = N'Трилер'
AND NOT EXISTS (SELECT 1 FROM BookGenres WHERE BookID = b.BookID AND GenreID = g.GenreID);

--  ЗАПОВНЮЄМО ВСІ ТЕГИ 

-- Теги для "Шлях королів"
INSERT INTO BookTags (BookID, TagID)
SELECT b.BookID, t.TagID FROM Books b, Tags t 
WHERE b.Title = N'Шлях королів' AND t.TagName IN (N'Епічне фентезі', N'Пригоди', N'Помста', N'Меч', N'Боротьба за владу', N'Магія', N'Смерть', N'Війна')
AND NOT EXISTS (SELECT 1 FROM BookTags WHERE BookID = b.BookID AND TagID = t.TagID);

-- Теги для "І не лишилось жодного"
INSERT INTO BookTags (BookID, TagID)
SELECT b.BookID, t.TagID FROM Books b, Tags t 
WHERE b.Title = N'І не лишилось жодного' AND t.TagName IN (N'Герметичний детектив', N'Помста')
AND NOT EXISTS (SELECT 1 FROM BookTags WHERE BookID = b.BookID AND TagID = t.TagID);

-- Теги для "Правда"
INSERT INTO BookTags (BookID, TagID)
SELECT b.BookID, t.TagID FROM Books b, Tags t 
WHERE b.Title = N'Правда' AND t.TagName IN (N'Дискосвіт', N'Газета')
AND NOT EXISTS (SELECT 1 FROM BookTags WHERE BookID = b.BookID AND TagID = t.TagID);

-- Теги для "Морт"
INSERT INTO BookTags (BookID, TagID)
SELECT b.BookID, t.TagID FROM Books b, Tags t 
WHERE b.Title = N'Морт' AND t.TagName IN (N'Дискосвіт', N'Магія', N'Смерть', N'Про життя')
AND NOT EXISTS (SELECT 1 FROM BookTags WHERE BookID = b.BookID AND TagID = t.TagID);

-- Теги для "Виживуть п'ятеро"
INSERT INTO BookTags (BookID, TagID)
SELECT b.BookID, t.TagID FROM Books b, Tags t 
WHERE b.Title = N'Виживуть п''ятеро' AND t.TagName IN (N'Герметичний детектив', N'Убивця', N'психологічний трилер', N'Відкритий фінал')
AND NOT EXISTS (SELECT 1 FROM BookTags WHERE BookID = b.BookID AND TagID = t.TagID);

-- Теги для "Кувала зозуля"
INSERT INTO BookTags (BookID, TagID)
SELECT b.BookID, t.TagID FROM Books b, Tags t 
WHERE b.Title = N'Кувала зозуля' AND t.TagName IN (N'Пригоди', N'Убивця', N'Кримінал')
AND NOT EXISTS (SELECT 1 FROM BookTags WHERE BookID = b.BookID AND TagID = t.TagID);

-- Теги для "Дев’ятий Дім"
INSERT INTO BookTags (BookID, TagID)
SELECT b.BookID, t.TagID FROM Books b, Tags t 
WHERE b.Title = N'Дев’ятий Дім' AND t.TagName IN (N'дарк академія', N'Магія', N'привиди', N'Убивця', N'Химерність', N'Трагедія', N'Академія', N'Кримінал', N'Різні часові проміжки')
AND NOT EXISTS (SELECT 1 FROM BookTags WHERE BookID = b.BookID AND TagID = t.TagID);

-- Теги для "Діва, матір і третя"
INSERT INTO BookTags (BookID, TagID)
SELECT b.BookID, t.TagID FROM Books b, Tags t 
WHERE b.Title = N'Діва, матір і третя' AND t.TagName IN (N'Відьми', N'Пригоди', N'Cozy(pleasant)', N'Магія', N'Гумор', N'Історія кохання')
AND NOT EXISTS (SELECT 1 FROM BookTags WHERE BookID = b.BookID AND TagID = t.TagID);

GO

 -- Встановлюємо, що "Шовкопряд" йде після "Кувала зозуля"
UPDATE Books 
SET PreviousBookID = (SELECT BookID FROM Books WHERE Title = N'Кувала зозуля')
WHERE Title = N'Шовкопряд';


-- ПЕРЕВІРКА
SELECT * FROM v_BookRatings;
