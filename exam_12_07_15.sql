USE Diablo
---Problem 1---
SELECT Name FROM Characters
ORDER BY Name

---Problem 2---
SELECT TOP 50 Name AS Game,CONVERT(nvarchar(10),Start,120) AS Start FROM Games
WHERE YEAR(Start) IN ('2011','2012')
ORDER BY Start, Name

---Problem 3---
SELECT Username, SUBSTRING(Email,CHARINDEX('@',Email,1)+1,LEN(Email)) AS [Email Provider] FROM Users
ORDER BY [Email Provider], Username

---Problem 4---
SELECT Username, IpAddress as [IP Address] FROM Users
WHERE IpAddress LIKE '[0-9][0-9][0-9].1[0-9]%.%.[0-9][0-9][0-9]'
ORDER BY Username

---Problem 5---
SELECT 
	Name AS Game,
	(CASE 
		WHEN DATENAME(hh,Start)>=0 AND DATENAME(hh,Start)<12 THEN 'Morning' 
		WHEN DATENAME(hh,Start)>=12 AND DATENAME(hh,Start)<18 THEN 'Afternoon' 
		WHEN DATENAME(hh,Start)>=18 AND DATENAME(hh,Start)<24  THEN 'Evening' END) AS [Part of the Day],
	(CASE 
		WHEN Duration IS NULL THEN 'Extra Long'
		WHEN Duration IN (0,1,2,3) THEN 'Extra Short' 
		WHEN Duration IN (4,5,6) THEN 'Short' 
		WHEN Duration > 6 THEN 'Long'  END) AS [Duration]
FROM Games
ORDER BY Name, [Duration], [Part of the Day]

SELECT * FROM Games WHERE Duration IS NULL

---Problem 6---
SELECT DISTINCT SUBSTRING(a.Email,CHARINDEX('@',a.Email,1)+1,LEN(a.Email)) AS [Email Provider], COUNT(s.Id) AS [Number Of Users] FROM Users a, Users s
WHERE SUBSTRING(a.Email,CHARINDEX('@',a.Email,1)+1,LEN(a.Email)) = SUBSTRING(s.Email,CHARINDEX('@',s.Email,1)+1,LEN(s.Email))
GROUP BY a.Email
ORDER BY [Number Of Users] DESC, [Email Provider] ASC

---Problem 7---
SELECT g.Name AS Game, gt.Name AS [Game Type], u.Username, ug.Level, ug.Cash, c.Name AS Character FROM Games g
JOIN GameTypes gt ON gt.Id = g.GameTypeId
JOIN UsersGames ug ON ug.GameId = g.Id
JOIN Users u ON u.Id = ug.UserId
JOIN Characters c ON c.Id = ug.CharacterId
ORDER BY ug.Level DESC, Username, Game

---Problem 8---
SELECT Username, g.Name AS Game, COUNT(i.Id) AS [Items Count], SUM(i.Price) AS [Items Price] FROM Users u
JOIN UsersGames ug ON ug.UserId = u.Id
JOIN Games g ON g.Id = ug.GameId
JOIN UserGameItems ugi ON ugi.UserGameId = ug.Id
JOIN Items i ON i.Id = ugi.ItemId
GROUP BY Username, g.Name
HAVING COUNT(i.Id)>=10
ORDER BY [Items Count] DESC, [Items Price] DESC, Username

---Problem 9--- TODO
SELECT DISTINCT u.Username, g.Name AS Game, c.Name AS [Character],
	SUM(s.Strength) AS Strength, 
	SUM(s.Defence) AS Defence, 
	SUM(s.Speed) AS Speed, 
	SUM(s.Mind) AS Mind,
	SUM(s.Luck) AS Luck 
FROM [Statistics] s
JOIN Characters c ON c.StatisticId = s.Id
JOIN Items i ON i.StatisticId = s.Id
JOIN UserGameItems ugi ON ugi.ItemId = i.Id
JOIN UsersGames ug ON ug.CharacterId = c.Id
JOIN Games g ON g.Id = ug.GameId
JOIN Users u ON ug.UserId = u.Id
GROUP BY u.Username, g.Name, c.Name, s.Strength,s.Defence,s.Speed,s.Mind,s.Luck
ORDER BY s.Strength DESC, s.Defence DESC, s.Speed DESC, s.Mind DESC,s.Luck DESC

SELECT u.Username, g.Name AS Game, c.Name AS [Character], 
	SUM(s.Strength + st.Strength + gst.Strength) AS Strength, 
	SUM(s.Defence + st.Defence + gst.Defence) AS Defence, 
	SUM(s.Speed + st.Speed + gst.Speed) AS Speed, 
	SUM(s.Mind + st.Mind + gst.Mind) AS Mind,
	SUM(s.Luck + st.Luck + gst.Luck) AS Luck
FROM Users u
JOIN UsersGames ug ON ug.UserId = u.Id
JOIN Games g ON g.Id = ug.GameId
JOIN Characters c ON c.Id = ug.CharacterId
JOIN UserGameItems ugi ON ugi.UserGameId = ug.Id
JOIN Items i ON i.Id = ugi.ItemId
JOIN GameTypes gt ON gt.Id = g.GameTypeId
JOIN [Statistics] st ON st.Id = i.StatisticId
JOIN [Statistics] s ON s.Id = c.StatisticId
JOIN [Statistics] gst ON gst.Id = gt.BonusStatsId
GROUP BY u.Username, g.Name, c.Name,s.Strength,s.Defence,s.Speed,s.Mind,s.Luck
ORDER BY s.Strength DESC, s.Defence DESC, s.Speed DESC, s.Mind DESC,s.Luck DESC

---Problem 10---
DECLARE @mind int = (SELECT AVG(Mind) FROM [Statistics] st JOIN Items i ON i.StatisticId = st.Id)

DECLARE @luck int = (SELECT AVG(Luck) FROM [Statistics] st JOIN Items i ON i.StatisticId = st.Id)

DECLARE @speed int = (SELECT AVG(Speed) FROM [Statistics] st JOIN Items i ON i.StatisticId = st.Id)


SELECT i.Name, i.Price, i.MinLevel, s.Strength, s.Defence, s.Speed, s.Luck, s.Mind FROM Items i
JOIN [Statistics] s ON s.Id = i.StatisticId
WHERE s.Mind>@mind AND s.Speed>@speed AND s.Luck>@luck 
ORDER BY i.Name

---Problem 11---
SELECT i.Name AS Item, i.Price, i.MinLevel, gt.Name AS [Forbidden Game Type] FROM Items i
LEFT JOIN GameTypeForbiddenItems gtfi ON gtfi.ItemId = i.Id
LEFT JOIN GameTypes gt ON gt.Id = gtfi.GameTypeId
ORDER BY [Forbidden Game Type] DESC, i.Name

---problem 14---
CREATE TABLE GameCash (
	Id int Identity(1,1) Primary Key NOT NULL,
	SumCash decimal(10,2) not null
)

CREATE FUNCTION ufn_CashInUsersGames(@game nvarchar(50)) 
RETURNS decimal(10,2)
AS
BEGIN
	DECLARE @gameId int = (SELECT Id FROM Games WHERE Name=@game)
	DECLARE @result decimal(10,2) = 0
	DECLARE cash_cursor CURSOR FOR
	SELECT Cash FROM UsersGames WHERE GameId = @gameId ORDER BY Cash DESC
	DECLARE @cash decimal(10,2)
	OPEN cash_cursor
	FETCH NEXT FROM cash_cursor INTO @cash
	WHILE @@FETCH_STATUS=0
	BEGIN
		SET @result=@result+@cash
		FETCH NEXT FROM cash_cursor INTO @cash
		FETCH NEXT FROM cash_cursor INTO @cash
	END
	CLOSE cash_cursor
	DEALLOCATE cash_cursor
	RETURN @result
END
GO

SELECT dbo.ufn_CashInUsersGames('Bali')
SELECT dbo.ufn_CashInUsersGames('Lily Stargazer')
SELECT dbo.ufn_CashInUsersGames('Love in a mist')
SELECT dbo.ufn_CashInUsersGames('Mimosa')
SELECT dbo.ufn_CashInUsersGames('Ming fern')

INSERT INTO GameCash (SumCash)
VALUES (21520.00), (5515.00), (8585.00), (12337.00), (7266.00)

SELECT SumCash FROM GameCash ORDER BY SumCash ASC

---Problem 12---
INSERT INTO UserGameItems
VALUES ((SELECT Id FROM Items WHERE Name='Hellfire Amulet'),
			(SELECT Id FROM UsersGames WHERE GameId = (SELECT Id FROM Games WHERE Name='Edinburgh') 
											AND UserId = (SELECT Id FROM Users WHERE Username='Alex')))

DECLARE @price decimal(10,2) = (SELECT Price FROM Items WHERE Name='Hellfire Amulet')

SELECT @price = Cash - @price FROM UsersGames WHERE GameId = (SELECT Id FROM Games WHERE Name='Edinburgh') 
											AND UserId = (SELECT Id FROM Users WHERE Username='Alex')

UPDATE UsersGames
SET Cash = @price
WHERE GameId = (SELECT Id FROM Games WHERE Name='Edinburgh') AND UserId = (SELECT Id FROM Users WHERE Username='Alex')

SELECT u.Username, 'Edinburgh' AS Name, ug.Cash, i.Name AS [Item Name] FROM UsersGames ug
JOIN Users u ON u.Id = ug.UserId
JOIN UserGameItems ugi ON ugi.UserGameId = ug.Id
JOIN Items i ON i.Id = ugi.ItemId
WHERE ug.GameId=(SELECT Id FROM Games WHERE Name='Edinburgh')
ORDER BY [Item Name]