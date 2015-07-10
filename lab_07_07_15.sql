---Problem 1---
SELECT q.Title FROM Questions q
ORDER BY q.Title ASC

---Problem 2---
SELECT a.Content, a.CreatedOn FROM Answers a
WHERE a.CreatedOn BETWEEN '2012-06-15 00:00:00' AND '2013-03-21 23:59:59'
ORDER BY a.CreatedOn ASC

---Problem 3---
SELECT u.Username,u.LastName, [Has Phone] =
	CASE 
		WHEN u.PhoneNumber IS NULL THEN 0
		ELSE 1
	END
FROM Users u
ORDER BY u.LastName

---Problem 4---
SELECT q.Title AS [Question Title], u.Username as Author FROM Questions q
JOIN Users u ON u.Id = q.UserId
ORDER BY q.Title ASC

---Problem 5---
SELECT TOP 50 a.Content as [Answer Content],
		a.CreatedOn,
		u.Username as [Answer Author],
		q.Title AS [Question Title],
		c.Name AS [Category Name]
FROM Answers a
JOIN Users u ON u.Id = a.UserId
JOIN Questions q ON q.Id = a.QuestionId
JOIN Categories c ON c.Id = q.CategoryId
ORDER BY c.Name, u.Username, a.CreatedOn

---Problem 6---
SELECT c.Name AS Category, q.Title AS Question, q.CreatedOn FROM Categories c
LEFT JOIN Questions q ON q.CategoryId = c.Id
ORDER BY c.Name, q.Title

---Problem 7---
SELECT u.Id, u.Username, u.FirstName, u.PhoneNumber, u.RegistrationDate, u.Email FROM Users u
WHERE u.PhoneNumber IS NULL AND u.Id NOT IN (SELECT q.UserId FROM Questions q)
ORDER BY u.RegistrationDate

---Problem 8---
SELECT MIN(a.CreatedOn) AS MinDate, MAX(a.CreatedOn) AS MaxDate FROM Answers a
WHERE a.CreatedON BETWEEN '2012-01-01 00:00:00' AND '2014-12-31 23:59:59'

---Problem 9----
SELECT TOP 10 a.Content AS Answer, a.CreatedOn, u.Username FROM Answers a
JOIN Users u ON u.Id = a.UserId
ORDER BY a.CreatedOn DESC

---Problem 10---
SELECT a.Content AS [Answer Content], q.Title AS Question, c.Name AS Category FROM Answers a
JOIN Questions q ON q.Id = a.QuestionId
JOIN Categories c ON c.Id = q.CategoryId
WHERE a.IsHidden=1 AND YEAR(a.CreatedOn) = (SELECT MAX(YEAR(an.CreatedOn)) FROM Answers an) 
	AND (MONTH(a.CreatedON) = ((SELECT MIN(Month(ans.CreatedOn)) FROM Answers ans)) OR MONTH(a.CreatedON) = ((SELECT MAX(Month(ans.CreatedOn)) FROM Answers ans)))
ORDER BY c.Name

---Problem 11---
SELECT c.Name AS Category, COUNT(a.Id) AS [Answers Count] FROM Answers a
RIGHT JOIN Categories c ON c.Id = (SELECT q.CategoryId FROM Questions q WHERE q.Id = a.QuestionId)
GROUP BY c.Name
ORDER BY [Answers Count] DESC

---Problem 12---
USE FORUM11
GO
SELECT c.Name AS Category, u.Username, u.PhoneNumber, COUNT(a.Id) AS [Answers Count] FROM Answers a
RIGHT JOIN (SELECT * FROM Users WHERE PhoneNumber IS NOT NULL) AS u ON u.Id = a.UserId
JOIN Categories c ON c.Id = (SELECT q.CategoryId FROM Questions q WHERE q.Id = a.QuestionId)
GROUP BY c.Name, u.Username, u.PhoneNumber
ORDER BY [Answers Count] DESC, u.Username ASC

---Problem 13---
CREATE TABLE Towns (
	Id int NOT NULL IDENTITY(1,1) PRIMARY KEY,
	Name nvarchar(50) NOT NULL
)
GO

ALTER TABLE Users
ADD TownId int FOREIGN KEY REFERENCES Towns(Id)

INSERT INTO Towns(Name) VALUES ('Sofia'), ('Berlin'), ('Lyon')
UPDATE Users SET TownId = (SELECT Id FROM Towns WHERE Name='Sofia')
INSERT INTO Towns VALUES
('Munich'), ('Frankfurt'), ('Varna'), ('Hamburg'), ('Paris'), ('Lom'), ('Nantes')

UPDATE Users
SET TownId = (SELECT Id FROM Towns WHERE Name='Paris')
WHERE DATEPART(dw, RegistrationDate)=5

UPDATE Answers
SET QuestionId = (SELECT Id FROM Questions WHERE Title='Java += operator')
WHERE DATEPART(m, CreatedOn)=2 AND(DATEPART(dw, CreatedOn)=1 OR DATEPART(dw, CreatedOn)=7)

SELECT a.Id INTO #AnswersToDelete FROM Answers a
JOIN Votes v ON a.Id = v.AnswerId
GROUP BY a.Id
HAVING (Sum(v.Value)<0)
DELETE v
FROM Votes v
JOIN #AnswersToDelete ON v.AnswerId = #AnswersToDelete.Id

DELETE a
FROM Answers a
JOIN #AnswersToDelete ON a.Id = #AnswersToDelete.Id

DROP TABLE #AnswersToDelete

INSERT INTO Questions (Title, Content, CreatedOn, UserId,CategoryId)
VALUES ('Fetch NULL values in PDO query', 'When I run the snippet, NULL values are converted to empty strings. How can fetch NULL values?', GETDATE(), (SELECT Id FROM Users WHERE Username='darkcat'), (SELECT Id FROM Categories WHERE Name='Databases'))
USE FORUM
GO
SELECT t.Name AS Town, u.Username, COUNT(a.Id) AS [Answer Count] FROM Answers a
LEFT JOIN Users u ON u.Id = a.UserId
LEFT JOIN Towns t ON t.Id = u.TownId
GROUP BY t.Name, u.Username
ORDER BY [Answer Count] DESC, Username ASC

SELECT * FROM Users where Username='micori'
UPDATE Users
SET TownId=1
WHERE Username='micori'
SELECT Id FROM Towns WHERE Name='Sofia'
---Problem 14---
USE [Forum11]
GO

CREATE VIEW AllQuestions
AS
SELECT 
	u.Id AS [UId], u.Username, u.FirstName, u.LastName, u.Email, u.PhoneNumber, u.RegistrationDate,
	q.Id AS QId, q.Title, q.Content, q.CategoryId, q.UserId, q.CreatedOn
FROM Questions q
RIGHT JOIN Users u ON q.UserId = u.Id

SELECT * FROM AllQuestions

CREATE FUNCTION ufn_ListUserQuestions() 
RETURNS @userQuestions TABLE (
	UserName nvarchar(50),
	Questions nvarchar(max)
)
AS
BEGIN
	INSERT INTO @userQuestions
		SELECT a.Username AS UserName, 
		STUFF(ISNULL((SELECT ', '+q.Title 
					FROM AllQuestions q 
					WHERE q.Username=a.Username
					GROUP BY q.Username, q.Title
					ORDER BY q.Title DESC
					FOR XML PATH(''), TYPE).value('.','NVARCHAR(MAX)'),''), 1, 2, '') AS Questions
		FROM AllQuestions a
	RETURN
END
GO

SELECT * FROM ufn_ListUserQuestions()