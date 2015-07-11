USE Geography
GO
---Problem 1---
SELECT p.PeakName FROM Peaks p
ORDER BY p.PeakName

---Problem 2---
SELECT TOP 30 c.CountryName , c.Population FROM Countries c
JOIN Continents con ON con.ContinentCode = c.ContinentCode
WHERE con.ContinentName='Europe'
ORDER BY c.Population DESC, c.CountryName ASC

---Problem 3---
SELECT c.CountryName, c.CountryCode, (CASE WHEN c.CurrencyCode='EUR' THEN 'Euro' ELSE 'Not Euro' END) AS Currency
FROM Countries c ORDER BY c.CountryName

---Problem 4---
SELECT CountryName AS [Country Name], IsoCode AS [ISO Code] FROM Countries
WHERE CountryName LIKE '%A%A%A%'
ORDER BY IsoCode

---Problem 5---
SELECT p.PeakName, m.MountainRange AS Mountain, p.Elevation FROM Peaks p
JOIN Mountains m ON m.Id = p.MountainId
ORDER BY p.Elevation DESC, p.PeakName

---Problem 6---
SELECT p.PeakName, m.MountainRange AS Mountain, c.CountryName, con.ContinentName FROM Peaks p
JOIN Mountains m ON m.Id = p.MountainId
JOIN MountainsCountries mc ON mc.MountainId = m.Id
JOIN Countries c ON c.CountryCode = mc.CountryCode
JOIN Continents con ON con.ContinentCode = c.ContinentCode
ORDER BY p.PeakName, c.CountryName

---Problem 7---
SELECT r.RiverName AS River, COUNT(c.CountryCode) AS [Countries Count] FROM Rivers r
JOIN CountriesRivers cr ON cr.RiverId = r.Id
JOIN Countries c ON c.CountryCode = cr.CountryCode
GROUP BY r.RiverName
HAVING (COUNT(c.CountryCode)>2)
ORDER BY River

---Problem 8---
SELECT MAX(Elevation) AS MaxElevation, MIN(Elevation) AS MinElevation, AVG(Elevation) AS AverageElevation FROM Peaks

---Problem 9---
SELECT c.CountryName, ct.ContinentName, ISNULL(COUNT(r.Id),0) AS RiversCount, ISNULL(SUM(r.Length),0) AS TotalLength FROM Countries c
JOIN Continents ct ON ct.ContinentCode = c.ContinentCode
LEFT JOIN CountriesRivers cr ON cr.CountryCode = c.CountryCode
LEFT JOIN Rivers r ON r.Id = cr.RiverId
GROUP BY c.CountryName, ct.ContinentName
ORDER BY RiversCount DESC, TotalLength DESC, c.CountryName

---Problem 10---
SELECT cur.CurrencyCode, cur.Description AS Currency, ISNULL(COUNT(c.CountryCode),0) AS NumberOfCountries FROM Currencies cur
LEFT JOIN Countries c ON c.CurrencyCode = cur.CurrencyCode
GROUP BY cur.CurrencyCode, cur.Description
ORDER BY NumberOfCountries DESC, cur.Description

---Problem 11---
SELECT 
	con.ContinentName, ISNULL(SUM(CONVERT(DECIMAL,c.AreaInSqKm)),0) AS CountriesArea, 
	ISNULL(SUM(CONVERT(DECIMAL,c.Population)),0) AS CountriesPopulation
FROM Continents con
LEFT JOIN Countries c ON c.ContinentCode = con.ContinentCode
GROUP BY con.ContinentName
ORDER BY CountriesPopulation DESC

---Problem 12---
SELECT
	c.CountryName,
	MAX(p.Elevation) AS HighestPeakElevation,
	MAX(r.Length) AS LongestRiverLength
FROM Countries c
LEFT JOIN CountriesRivers cr ON cr.CountryCode = c.CountryCode
LEFT JOIN Rivers r ON r.Id = cr.RiverId
LEFT JOIN MountainsCountries mc ON mc.CountryCode = c.CountryCode
LEFT JOIN Mountains m ON m.Id = mc.MountainId
LEFT JOIN Peaks p ON p.MountainId = m.Id
GROUP BY c.CountryName
ORDER BY HighestPeakElevation DESC, LongestRiverLength DESC, c.CountryName

---Problem 13---
SELECT p.PeakName, r.RiverName, LOWER(SUBSTRING(p.PeakName, 1,LEN(p.PeakName)-1)+r.RiverName) AS Mix FROM Peaks p, Rivers r
WHERE SUBSTRING(r.RiverName, 1,1) = SUBSTRING(p.PeakName,LEN(p.PeakName), 1)
ORDER BY Mix

---Problem 14---
SELECT
	c.CountryName AS Country,
	p.PeakName AS [Highest Peak Name],
	p.Elevation AS [Highest Peak Elevation],
	m.MountainRange AS Mountain
FROM Countries c
LEFT JOIN MountainsCountries mc ON mc.CountryCode = c.CountryCode
LEFT JOIN Mountains m ON m.Id = mc.MountainId
LEFT JOIN Peaks p ON p.MountainId = m.Id
WHERE p.Elevation = (
	SELECT MAX(p.Elevation) FROM MountainsCountries mc
	LEFT JOIN Mountains m ON mc.MountainId = m.Id
	LEFT JOIN Peaks p ON p.MountainId = m.Id
	WHERE mc.CountryCode = c.CountryCode)
UNION 
SELECT
	c.CountryName AS Country,
	'(no highest peak)' AS [Highest Peak Name],
	0 AS [Highest Peak Elevation],
	'(no mountain)' AS Mountain
FROM Countries c
LEFT JOIN MountainsCountries mc ON mc.CountryCode = c.CountryCode
LEFT JOIN Mountains m ON m.Id = mc.MountainId
LEFT JOIN Peaks p ON p.MountainId = m.Id
WHERE 
	(SELECT MAX(p.Elevation) FROM MountainsCountries mc
	LEFT JOIN Mountains m ON mc.MountainId = m.Id
	LEFT JOIN Peaks p ON p.MountainId = m.Id
	WHERE mc.CountryCode = c.CountryCode) IS NULL
GROUP BY c.CountryName, p.PeakName, m.MountainRange
ORDER BY c.CountryName, p.PeakName

---Problem 17---
DROP FUNCTION dbo.ufn_MountainsPeaksJSON

CREATE FUNCTION dbo.ufn_MountainsPeaksJSON() RETURNS NVARCHAR(MAX)
AS
BEGIN
	DECLARE @json NVARCHAR(MAX)
	SET @json = '{"mountains":['
	
	DECLARE mt_cursor CURSOR FOR
	SELECT Id, MountainRange FROM Mountains

	OPEN mt_cursor
	DECLARE @mName NVARCHAR(MAX), @mId INT
	FETCH NEXT FROM mt_cursor INTO @mId, @mName
	WHILE @@FETCH_STATUS=0
	BEGIN
		SET @json = @json + '{"name":"'+@mName+'","peaks":['

		DECLARE p_cursor CURSOR FOR
		SELECT PeakName, Elevation FROM Peaks Where MountainId = @mId
		OPEN p_cursor
		DECLARE @pName NVARCHAR(MAX), @pEle INT
		FETCH NEXT FROM p_cursor INTO @pName, @pEle
		WHILE @@FETCH_STATUS=0
		BEGIN
			SET @json=@json+'{"name":"'+@pName+'","elevation":'+CONVERT(nvarchar(max),@pEle)+'}'
			FETCH NEXT FROM p_cursor INTO @pName, @pEle
			IF @@FETCH_STATUS=0
			BEGIN 
				SET @json=@json+','
			END
		END
		SET @json=@json+']}'
		FETCH NEXT FROM mt_cursor INTO @mId, @mName
		IF @@FETCH_STATUS=0
		BEGIN 
			SET @json=@json+','
		END
		CLOSE p_cursor
		DEALLOCATE p_cursor
	END
	CLOSE mt_cursor
	DEALLOCATE mt_cursor
	SET @json=@json+']}'
	RETURN @json
END
GO

SELECT dbo.ufn_MountainsPeaksJSON()

---Problem 15---
CREATE TABLE Monasteries (
	Id int IDENTITY(1,1) PRIMARY KEY NOT NULL,
	Name nvarchar(50) NOT NULL,
	CountryCode char(2) FOREIGN KEY REFERENCES Countries(CountryCode)
)

INSERT INTO Monasteries(Name, CountryCode) VALUES
('Rila Monastery “St. Ivan of Rila”', 'BG'), 
('Bachkovo Monastery “Virgin Mary”', 'BG'),
('Troyan Monastery “Holy Mother''s Assumption”', 'BG'),
('Kopan Monastery', 'NP'),
('Thrangu Tashi Yangtse Monastery', 'NP'),
('Shechen Tennyi Dargyeling Monastery', 'NP'),
('Benchen Monastery', 'NP'),
('Southern Shaolin Monastery', 'CN'),
('Dabei Monastery', 'CN'),
('Wa Sau Toi', 'CN'),
('Lhunshigyia Monastery', 'CN'),
('Rakya Monastery', 'CN'),
('Monasteries of Meteora', 'GR'),
('The Holy Monastery of Stavronikita', 'GR'),
('Taung Kalat Monastery', 'MM'),
('Pa-Auk Forest Monastery', 'MM'),
('Taktsang Palphug Monastery', 'BT'),
('Sümela Monastery', 'TR')

ALTER TABLE Countries
ADD IsDeleted bit DEFAULT 0
GO

UPDATE Countries
SET IsDeleted=1 
WHERE CountryName IN (SELECT c.CountryName FROM Countries c
JOIN Continents ct ON ct.ContinentCode = c.ContinentCode
LEFT JOIN CountriesRivers cr ON cr.CountryCode = c.CountryCode
LEFT JOIN Rivers r ON r.Id = cr.RiverId
GROUP BY c.CountryName, ct.ContinentName
HAVING (COUNT(r.Id)>3))

SELECT m.Name AS Monastery, c.CountryName AS Country FROM Monasteries m
JOIN Countries c ON c.CountryCode = m.CountryCode WHERE c.IsDeleted IS NULL
GROUP BY m.Name, c.CountryName
ORDER BY m.Name

---Problem 16---
UPDATE Countries
SET CountryName='Burma'
WHERE CountryName='Myanmar'

INSERT INTO Monasteries (Name, CountryCode)
VALUES ('Hanga Abbey', (SELECT CountryCode FROM Countries WHERE CountryName='Tanzania')),
('Myin-Tin-Daik', (SELECT CountryCode FROM Countries WHERE CountryName='Myanmar'))

SELECT ct.ContinentName, c.CountryName, COUNT(m.Id) AS MonasteriesCount FROM Continents ct
JOIN Countries c ON c.ContinentCode = ct.ContinentCode
LEFT JOIN Monasteries m ON m.CountryCode = c.CountryCode
WHERE c.IsDeleted IS NULL
GROUP BY ct.ContinentName, c.CountryName
ORDER BY MonasteriesCount DESC, c.CountryName ASC

---Problem 18 MySQL---
DROP DATABASE if exists trainings;

create database trainings;
use trainings;
create table training_centers (
	id int(11) primary key auto_increment not null,
    name nvarchar(50) not null,
    description nvarchar(255),
    url nvarchar(100)
);

create table courses (
	id int(11) primary key auto_increment not null,
	name nvarchar(50) not null,
    description nvarchar(255)
);

create table course_timetable (
	id int(11) primary key auto_increment not null,
	course_id int(11) not null,
    training_center_id int(11) not null,
    starting_date date not null,
    KEY fk_course_timetable_courses_idx (course_id),
    KEY fk_course_timetable_training_centers_idx (training_center_id),
    constraint fk_course_timetable_courses foreign key (course_id) references courses(id) on delete no action on update no action,
    constraint fk_course_timetable_training_centers_idx foreign key (training_center_id) references training_centers(id) on delete no action on update no action
);

INSERT INTO `training_centers` VALUES (1, 'Sofia Learning', NULL, 'http://sofialearning.org'), (2, 'Varna Innovations & Learning', 'Innovative training center, located in Varna. Provides trainings in software development and foreign languages', 'http://vil.edu'), (3, 'Plovdiv Trainings & Inspiration', NULL, NULL),
(4, 'Sofia West Adult Trainings', 'The best training center in Lyulin', 'https://sofiawest.bg'), (5, 'Software Trainings Ltd.', NULL, 'http://softtrain.eu'),
(6, 'Polyglot Language School', 'English, French, Spanish and Russian language courses', NULL), (7, 'Modern Dances Academy', 'Learn how to dance!', 'http://danceacademy.bg');

INSERT INTO `courses` VALUES (101, 'Java Basics', 'Learn more at https://softuni.bg/courses/java-basics/'), (102, 'English for beginners', '3-month English course'), (103, 'Salsa: First Steps', NULL), (104, 'Avancée Français', 'French language: Level III'), (105, 'HTML & CSS', NULL), (106, 'Databases', 'Introductionary course in databases, SQL, MySQL, SQL Server and MongoDB'), (107, 'C# Programming', 'Intro C# corse for beginners'), (108, 'Tango dances', NULL), (109, 'Spanish, Level II', 'Aprender Español');

INSERT INTO `course_timetable`(course_id, training_center_id, starting_date) VALUES (101, 1, '2015-01-31'), (101, 5, '2015-02-28'), (102, 6, '2015-01-21'), (102, 4, '2015-01-07'), (102, 2, '2015-02-14'), (102, 1, '2015-03-05'), (102, 3, '2015-03-01'), (103, 7, '2015-02-25'), (103, 3, '2015-02-19'), (104, 5, '2015-01-07'), (104, 1, '2015-03-30'), (104, 3, '2015-04-01'), (105, 5, '2015-01-25'), (105, 4, '2015-03-23'), (105, 3, '2015-04-17'), (105, 2, '2015-03-19'), (106, 5, '2015-02-26'), (107, 2, '2015-02-20'), (107, 1, '2015-01-20'), (107, 3, '2015-03-01'), (109, 6, '2015-01-13');

UPDATE `course_timetable` t JOIN `courses` c ON t.course_id = c.id
SET t.starting_date = DATE_SUB(t.starting_date, INTERVAL 7 DAY)
WHERE c.name REGEXP '^[a-j]{1,5}.*s$';

select tc.name as 'training center', ct.starting_date as 'start date', c.name as 'course name', c.description as 'more info' from course_timetable ct
join training_centers tc on tc.id = ct.training_center_id
join courses c on c.id = ct.course_id
order by ct.starting_date, ct.id;