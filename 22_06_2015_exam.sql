USE Football
---Problem 1---
SELECT TeamName FROM Teams
ORDER BY TeamName

---Problem 2---
SELECT TOP 50 CountryName, Population FROM Countries
ORDER BY Population DESC, CountryName ASC

---Problem 3---
SELECT CountryName, CountryCode, (CASE WHEN CurrencyCode = 'EUR' THEN 'Inside' ELSE 'Outside' END) AS Eurozone FROM Countries
ORDER BY CountryName

---Problem 4---
SELECT t.TeamName as [Team Name], t.CountryCode AS [Country Code] FROM Teams t
JOIN Countries c ON c.CountryCode = t.CountryCode
WHERE t.TeamName LIKE '%[0-9]%'
ORDER BY t.CountryCode

---Problem 5---
SELECT c.CountryName as [Home Team], ct.CountryName AS [Away Team], MatchDate AS [Match Date] FROM InternationalMatches im
JOIN Countries c ON im.HomeCountryCode = c.CountryCode
JOIN Countries ct ON im.AwayCountryCode = ct.CountryCode
ORDER BY MatchDate DESC

---Problem 6---
SELECT 
	t.TeamName AS [Team Name], 
	l.LeagueName AS League, 
	(CASE WHEN l.CountryCode IS NULL THEN 'International' ELSE c.CountryName END) AS [League Country] 
FROM Teams t
JOIN Leagues_Teams lt ON t.Id=lt.TeamId
JOIN Leagues l ON l.Id = lt.LeagueId
LEFT JOIN Countries c ON c.CountryCode = l.CountryCode
ORDER BY t.TeamName, l.LeagueName

---Problem 7---
SELECT TeamName AS Team, COUNT(tm.Id) AS [Matches Count] FROM Teams t
JOIN TeamMatches tm ON tm.AwayTeamId = t.Id OR tm.HomeTeamId = t.Id
GROUP BY TeamName
HAVING (COUNT(tm.Id)>1)
ORDER BY TeamName

---Problem 8---
SELECT l.LeagueName AS [League Name], COUNT(DISTINCT lt.TeamId) AS Teams, COUNT(DISTINCT tm.Id) AS Matches, ISNULL(AVG(tm.AwayGoals+tm.HomeGoals),0) AS [Average Goals] FROM Leagues l
LEFT JOIN Leagues_Teams lt ON l.Id = lt.LeagueId
LEFT JOIN TeamMatches tm ON tm.LeagueId = l.Id
GROUP BY l.LeagueName
ORDER BY Teams DESC, Matches DESC

---Problem 9---
SELECT 
	t.TeamName,
	ISNULL(SUM(tm.AwayGoals),0)+ISNULL(SUM(tm1.HomeGoals),0) AS [Total Goals] 
FROM Teams t
LEFT JOIN TeamMatches tm ON tm.AwayTeamId = t.Id 
LEFT JOIN TeamMatches tm1 ON tm1.HomeTeamId = t.Id
GROUP BY t.TeamName
ORDER BY [Total Goals] DESC, t.TeamName ASC

---Problem 10---
SELECT tm.MatchDate as [First Date], tm1.MatchDate AS [Second Date] FROM TeamMatches tm,TeamMatches tm1
WHERE tm.MatchDate<tm1.MatchDate AND DATEDIFF(day,tm.MatchDate,tm1.MatchDate)<1
ORDER BY tm.MatchDate DESC, tm1.MatchDate DESC

---Problem 11--
SELECT LOWER(SUBSTRING(t.TeamName,1,LEN(t.TeamName)-1)+REVERSE(t1.TeamName)) AS Mix FROM Teams t, Teams t1
WHERE SUBSTRING(t.TeamName,LEN(t.TeamName),1)=SUBSTRING(t1.TeamName,LEN(t1.TeamName),1)
ORDER BY Mix

---Problem 12---
SELECT 
	c.CountryName AS [Country Name],
	COUNT(DISTINCT im1.Id) AS [International Matches],
	COUNT(DISTINCT tm.Id) AS [Team Matches]
FROM Countries c
LEFT JOIN InternationalMatches im1 ON im1.HomeCountryCode=c.CountryCode OR im1.AwayCountryCode=c.CountryCode
LEFT JOIN Leagues l ON l.CountryCode = c.CountryCode
LEFT JOIN TeamMatches tm ON tm.LeagueId = l.Id
GROUP BY c.CountryName
HAVING (COUNT(DISTINCT im1.Id)>0 OR COUNT(DISTINCT tm.Id)>0)
ORDER BY [International Matches] DESC, [Team Matches] DESC,c.CountryName

---Problem 13---
CREATE TABLE FriendlyMatches (
	Id int IDENTITY(1,1) PRIMARY KEY NOT NULL,
	HomeTeamID int FOREIGN KEY REFERENCES Teams(Id) NOT NULL,
	AwayTeamId int FOREIGN KEY REFERENCES Teams(Id) NOT NULL,
	MatchDate datetime NOT NULL
)

INSERT INTO Teams(TeamName) VALUES
 ('US All Stars'),
 ('Formula 1 Drivers'),
 ('Actors'),
 ('FIFA Legends'),
 ('UEFA Legends'),
 ('Svetlio & The Legends')
GO

INSERT INTO FriendlyMatches(
  HomeTeamId, AwayTeamId, MatchDate) VALUES
  
((SELECT Id FROM Teams WHERE TeamName='US All Stars'), 
 (SELECT Id FROM Teams WHERE TeamName='Liverpool'),
 '30-Jun-2015 17:00'),
 
((SELECT Id FROM Teams WHERE TeamName='Formula 1 Drivers'), 
 (SELECT Id FROM Teams WHERE TeamName='Porto'),
 '12-May-2015 10:00'),
 
((SELECT Id FROM Teams WHERE TeamName='Actors'), 
 (SELECT Id FROM Teams WHERE TeamName='Manchester United'),
 '30-Jan-2015 17:00'),

((SELECT Id FROM Teams WHERE TeamName='FIFA Legends'), 
 (SELECT Id FROM Teams WHERE TeamName='UEFA Legends'),
 '23-Dec-2015 18:00'),

((SELECT Id FROM Teams WHERE TeamName='Svetlio & The Legends'), 
 (SELECT Id FROM Teams WHERE TeamName='Ludogorets'),
 '22-Jun-2015 21:00')

GO

SELECT 
	(SELECT TeamName FROM Teams WHERE tm.HomeTeamId = Id) AS [Home Team], 
	(SELECT TeamName FROM Teams WHERE tm.AwayTeamId = Id) AS [Away Team], 
	tm.MatchDate AS [Match Date]
FROM Teams t
LEFT JOIN TeamMatches tm ON t.Id = tm.HomeTeamId or t.Id=tm.AwayTeamId
UNION
SELECT 
	(SELECT TeamName FROM Teams WHERE fm.HomeTeamId = Id) AS [Home Team], 
	(SELECT TeamName FROM Teams WHERE fm.AwayTeamId = Id) AS [Away Team], 
	fm.MatchDate AS [Match Date]
FROM Teams t
LEFT JOIN FriendlyMatches fm ON t.Id = fm.HomeTeamId or t.Id=fm.AwayTeamId
WHERE TeamName IS NOT NULL
ORDER BY [Match Date] DESC

---Problem 14---
ALTER TABLE Leagues
ADD IsSeasonal BIT default 0

INSERT INTO TeamMatches (HomeTeamId, AwayTeamId, HomeGoals, AwayGoals, MatchDate, LeagueId)
VALUES (
	(SELECT Id FROM Teams WHERE TeamName = 'Empoli'),
	(SELECT Id FROM Teams WHERE TeamName = 'Parma'),
	2,2,'19-Apr-2015 16:00',
	(SELECT Id FROM Leagues WHERE LeagueName='Italian Serie A')
)

INSERT INTO TeamMatches (HomeTeamId, AwayTeamId, HomeGoals, AwayGoals, MatchDate, LeagueId)
VALUES (
	(SELECT Id FROM Teams WHERE TeamName = 'Internazionale'),
	(SELECT Id FROM Teams WHERE TeamName = 'AC Milan'),
	0,0,'19-Apr-2015 21:45',
	(SELECT Id FROM Leagues WHERE LeagueName='Italian Serie A')
)

UPDATE Leagues 
SET IsSeasonal = 1
WHERE Id IN (SELECT l.Id FROM Leagues l
JOIN TeamMatches tm ON tm.LeagueId = l.Id
GROUP BY l.Id
HAVING (COUNT(tm.Id))>0)

SELECT 
(SELECT TeamName FROM Teams WHERE Id=tm.HomeTeamId) AS [Home Team], 
tm.HomeGoals AS [Home Goals],
(SELECT TeamName FROM Teams WHERE Id=tm.AwayTeamId) As [Away Team], 
tm.AwayGoals AS [Away Goals],
(SELECT LeagueName FROM Leagues WHERE Id=tm.LeagueId) AS [League Name] 
FROM TeamMatches tm
WHERE tm.MatchDate>'2015-04-10'
ORDER BY [League Name],[Home Goals] DESC,[Away Goals] DESC

---Problem 15---
CREATE FUNCTION ufn_TeamsJSON() RETURNS NVARCHAR(max)
AS
BEGIN
	DECLARE @json nvarchar(max) = '{"teams":['
	DECLARE team_cursor CURSOR FOR 
	SELECT t.TeamName, t.Id FROM Teams t
	WHERE t.CountryCode = (SELECT c.CountryCode FROM Countries c WHERE c.CountryName='Bulgaria')
	ORDER BY t.TeamName
	OPEN team_cursor
	DECLARE @tName nvarchar(max), @tId int
	FETCH NEXT FROM team_cursor INTO @tName, @tId
	WHILE @@FETCH_STATUS=0
	BEGIN
		SET @json=@json+'{"name":"'+@tName+'","matches":['
		DECLARE match_cursor CURSOR FOR
		SELECT m.HomeTeamId, m.AwayTeamId, m.HomeGoals, m.AwayGoals, m.MatchDate FROM TeamMatches m
		WHERE m.HomeTeamId = @tId OR m.AwayTeamId=@tId
		ORDER BY m.MatchDate DESC
		OPEN match_cursor
		DECLARE @mHomeId int, @mAwayId int, @hGoals int, @aGoals int, @date datetime
		FETCH NEXT FROM match_cursor INTO @mHomeId, @mAwayId, @hGoals, @aGoals, @date
		WHILE @@FETCH_STATUS=0
		BEGIN
			SET @json=@json+'{'
			IF @tId=@mHomeId
				BEGIN
					SET @json=@json+'"'+@tName+'":'+CONVERT(nvarchar(max),@hGoals)+','
					SET @json=@json+'"'+(SELECT TeamName FROM Teams WHERE Id = @mAwayId)+'":'+CONVERT(nvarchar(max),@aGoals)+','
					SET @json=@json+'"date":'+CONVERT(nvarchar(max),@date,103)
				END
			IF @tId=@mAwayId
				BEGIN
					SET @json=@json+'"'+(SELECT TeamName FROM Teams WHERE Id = @mHomeId)+'":'+CONVERT(nvarchar(max),@hGoals)+','
					SET @json=@json+'"'+@tName+'":'+CONVERT(nvarchar(max),@aGoals)+','
					SET @json=@json+'"date":'+CONVERT(nvarchar(max),@date,103)
				END
			SET @json=@json+'}'
			FETCH NEXT FROM match_cursor INTO @mHomeId, @mAwayId, @hGoals, @aGoals, @date
			IF @@FETCH_STATUS=0
			BEGIN
				SET @json=@json+','
			END
		END
		SET @json=@json+']}'
		FETCH NEXT FROM team_cursor INTO @tName, @tId
		IF @@FETCH_STATUS=0
		BEGIN
			SET @json=@json+','
		END
		CLOSE match_cursor
		DEALLOCATE match_cursor
	END
	CLOSE team_cursor
	DEALLOCATE team_cursor
	SET @json = @json+']}'
	RETURN @json
END
GO

SELECT dbo.ufn_TeamsJSON()

DROP FUNCTION ufn_TeamsJSON