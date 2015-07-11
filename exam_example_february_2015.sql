USE Ads
Go

---Problem 1---
SELECT Title FROM Ads
ORDER BY Title ASC

---Problem 2---
SELECT a.Title, a.Date FROM Ads a
WHERE a.Date BETWEEN '26-December-2014 00:00:00' AND '1-January-2015 23:59:59'
ORDER BY Date ASC

---Problem 3---
SELECT Title, Date,  [Has Image] = 
	CASE 
		WHEN ImageDataURL IS NULL THEN 'no'
		ELSE 'yes'
	END
FROM Ads
ORDER BY id

---Problem 4---
SELECT * FROM Ads
WHERE ImageDataURL IS NULL OR TownId IS NULL OR CategoryId IS NULL
ORDER BY Id

---Problem 5---
SELECT a.Title, t.Name AS Town FROM Ads a
LEFT JOIN Towns t ON a.TownId = t.Id
ORDER BY a.Id

---Problem 6---
SELECT a.Title, c.Name AS CategoryName, t.Name AS TownName, s.Status FROM Ads a
LEFT JOIN Categories c ON c.Id = a.CategoryId
LEFT JOIN Towns t ON t.Id = a.TownId
LEFT JOIN AdStatuses s ON s.Id = a.StatusId
ORDER BY a.Id

---Problem 7---
SELECT a.Title, c.Name AS CategoryName, t.Name AS TownName, s.Status FROM Ads a
LEFT JOIN Categories c ON c.Id = a.CategoryId
LEFT JOIN AdStatuses s ON s.Id = a.StatusId
LEFT JOIN Towns t ON t.Id = a.TownId 
WHERE t.Name IN ('Sofia','Stara Zagora','Blagoevgrad') AND s.Status = 'Published'
ORDER BY a.Title

---Problem 8---
SELECT MIN(Date) AS MinDate, MAX(Date) AS MaxDate FROM Ads

---Problem 9---
SELECT TOP 10 a.Title, a.Date, s.Status FROM Ads a
JOIN AdStatuses s ON s.Id=a.StatusId
ORDER BY A.Date DESC

---Problem 10---
DECLARE @minMonth int,@minYear int
SELECT @minMonth = DATEPART(m,MIN(Date)), @minYear=DATENAME(yyyy,MIN(Date)) FROM Ads
SELECT a.Id, a.Title, a.Date, s.Status FROM Ads a
JOIN AdStatuses s ON s.Id = a.StatusId
WHERE DATEPART(m,Date) = @minMonth AND DATENAME(yyyy,Date)=@minYear AND s.Status!='Published'
ORDER BY a.Id

---Problem 11---
SELECT s.Status, COUNT(a.Id) AS Count FROM Ads a
JOIN AdStatuses s ON s.Id = a.StatusId
GROUP BY s.Status
ORDER BY s.Status

---Problem 12---
SELECT t.Name AS [Town Name], s.Status, Count(a.Id) AS Count FROM Ads a
JOIN Towns t ON t.Id = a.TownId
JOIN AdStatuses s ON s.Id = a.StatusId
GROUP BY t.Name, s.Status
ORDER BY t.Name, s.Status

---Problem 13---
SELECT DISTINCT u.UserName, COUNT(a.Id) AS AdsCount, IsAdministrator = 
	CASE
		WHEN j.UserName IS NULL THEN 'no'
		ELSE 'yes'
	END
FROM AspNetUsers u
LEFT JOIN Ads a ON a.OwnerId = u.Id
LEFT JOIN (SELECT DISTINCT ur.UserName FROM AspNetUsers ur 
	LEFT JOIN AspNetUserRoles usr ON ur.Id = usr.UserId
	LEFT JOIN AspNetRoles r ON r.Id = usr.RoleId WHERE r.Name='Administrator') AS j ON j.UserName = u.UserName
GROUP BY u.UserName, j.UserName
ORDER BY u.UserName

---Problem 14--
SELECT COUNT(a.Id) AS AdsCount, Town =
	CASE 
		WHEN t.Name IS NULL THEN '(no town)'
		ELSE t.Name
	END
FROM Ads a
LEFT JOIN Towns t ON t.Id=a.TownId
GROUP BY t.Name
HAVING COUNT(a.Id)=2 OR COUNT(a.Id)=3
ORDER BY t.Name

---Problem 15---
SELECT a.Date AS FirstDate, b.Date AS SecondDate FROM Ads a, Ads b
WHERE b.Date>a.Date AND DATEDIFF(HOUR, a.Date, b.Date)<12
ORDER BY a.Date, b.Date

---Problem 16---
USE Ads
GO
CREATE TABLE Countries (
	Id int IDENTITY(1,1) PRIMARY KEY,
	Name NVARCHAR(50) NOT NULL
)

ALTER TABLE Towns 
ADD CountryId int FOREIGN KEY REFERENCES Countries(Id)

INSERT INTO Countries(Name) VALUES ('Bulgaria'), ('Germany'), ('France')
UPDATE Towns SET CountryId = (SELECT Id FROM Countries WHERE Name='Bulgaria')
INSERT INTO Towns VALUES
('Munich', (SELECT Id FROM Countries WHERE Name='Germany')),
('Frankfurt', (SELECT Id FROM Countries WHERE Name='Germany')),
('Berlin', (SELECT Id FROM Countries WHERE Name='Germany')),
('Hamburg', (SELECT Id FROM Countries WHERE Name='Germany')),
('Paris', (SELECT Id FROM Countries WHERE Name='France')),
('Lyon', (SELECT Id FROM Countries WHERE Name='France')),
('Nantes', (SELECT Id FROM Countries WHERE Name='France'))

UPDATE Ads
SET TownId = (SELECT Id FROM Towns WHERE Name='Paris')
WHERE DATENAME(dw,Date)='Friday'

UPDATE Ads
SET TownId = (SELECT Id FROM Towns WHERE Name='Hamburg')
WHERE DATENAME(dw,Date)='Thursday'

CREATE TABLE #tmpAdsId (AdsId int)
INSERT INTO #tmpAdsId
SELECT a.Id FROM Ads a
JOIN AspNetUsers au ON au.Id=a.OwnerId
JOIN (SELECT DISTINCT ur.UserName FROM AspNetUsers ur 
	LEFT JOIN AspNetUserRoles usr ON ur.Id = usr.UserId
	LEFT JOIN AspNetRoles r ON r.Id = usr.RoleId WHERE r.Name='Partner') AS j ON j.UserName = au.UserName
ORDER BY a.Id

DROP TABLE #tmpAdsId
SELECT * FROM #tmpAdsId

SELECT Id , TownId FROM Ads
WHERE TownId IS NULL

INSERT INTO Ads(Title, Text, Date, OwnerId, StatusId)
VALUES ('Free Book', 'Free C# Book', GETDATE(), 
(SELECT Id FROM AspNetUsers WHERE UserName='nakov'), 
(SELECT Id FROM AdStatuses WHERE Status='Waiting Approval'))

SELECT t.Name AS Town, c.Name AS Country, COUNT(a.Id) AS AdsCount FROM Ads a 
FULL OUTER JOIN Towns t ON t.Id = a.TownId
FULL OUTER JOIN Countries c ON c.Id = t.CountryId
GROUP BY t.Name, c.Name
ORDER BY t.Name, c.Name

---Problem 17---
CREATE VIEW AllAds
AS 
SELECT a.Id, a.Title, u.UserName AS Author, a.Date, t.Name AS Town, c.Name AS Category, s.Status 
FROM Ads a
LEFT JOIN AspNetUsers u ON u.Id = a.OwnerId
LEFT JOIN Towns t ON t.Id = a.TownId
LEFT JOIN Categories c ON c.Id = a.CategoryId
LEFT JOIN AdStatuses s ON s.Id = a.StatusId

SELECT * FROM AllAds

IF (object_id(N'ufn_ListUsersAds') IS NOT NULL)
DROP FUNCTION ufn_ListUsersAds
GO

CREATE FUNCTION ufn_ListUsersAds() 
RETURNS @authorDates TABLE 
	(UserName nvarchar(50),
	AdDates nvarchar(max))
AS
BEGIN
	DECLARE UserCursor CURSOR FOR
	SELECT UserName FROM AspNetUsers
	ORDER BY UserName DESC
	OPEN UserCursor
	DECLARE @username nvarchar(50)
	FETCH NEXT FROM UserCursor INTO @username
	WHILE @@FETCH_STATUS=0
		BEGIN
			DECLARE @ads nvarchar(max) = NULL
			SELECT @ads = 
			CASE 
				WHEN @ads IS NULL THEN CONVERT(NVARCHAR(MAX),Date, 112)
				ELSE @ads + '; ' + CONVERT(NVARCHAR(MAX),Date, 112)
			END
			FROM AllAds 
			WHERE Author = @username
			ORDER BY Date
			INSERT INTO @authorDates
			VALUES(@username,@ads)

			FETCH NEXT FROM UserCursor INTO @username
		END
	CLOSE UserCursor
	DEALLOCATE UserCursor
	RETURN
END
GO

SELECT * FROM ufn_ListUsersAds()

---Problem 18 MySQL---
DROP DATABASE IF EXISTS orders;

CREATE DATABASE orders;

USE orders;

CREATE TABLE products (
	id int(11) primary key auto_increment NOT NULL,
    name varchar(50) NOT NULL,
    price decimal(10,2) NOT NULL
);

CREATE TABLE customers (
	id int(11) primary key auto_increment NOT NULL,
    name varchar(50) NOT NULL
);

create table orders (
	id int(11) primary key auto_increment NOT NULL,
    date datetime NOT NULL
);

create table order_items (
	id int(11) primary key auto_increment NOT NULL,
    order_id int(11) NOT NULL,
    product_id int(11) NOT NULL,
    quantity decimal(10,2) NOT NULL,
    KEY fk_order_items_orders_idx (order_id),
    KEY fk_order_items_products_idx (product_id),
    constraint fk_order_items_orders_idx foreign key (order_id) references orders(id) on delete no action on update no action,
    constraint fk_order_items_products_idx foreign key (product_id) references products(id) on delete no action on update no action
);

INSERT INTO `products` VALUES (1,'beer',1.20), (2,'cheese',9.50), (3,'rakiya',12.40), (4,'salami',6.33), (5,'tomatos',2.50), (6,'cucumbers',1.35), (7,'water',0.85), (8,'apples',0.75);
INSERT INTO `customers` VALUES (1,'Peter'), (2,'Maria'), (3,'Nakov'), (4,'Vlado');
INSERT INTO `orders` VALUES (1,'2015-02-13 13:47:04'), (2,'2015-02-14 22:03:44'), (3,'2015-02-18 09:22:01'), (4,'2015-02-11 20:17:18');
INSERT INTO `order_items` VALUES (12,4,6,2.00), (13,3,2,4.00), (14,3,5,1.50), (15,2,1,6.00), (16,2,3,1.20), (17,1,2,1.00), (18,1,3,1.00), (19,1,4,2.00), (20,1,5,1.00), (21,3,1,4.00), (22,1,1,3.00);

USE orders;
select p.name as product_name, 
	count(oi.order_id) as num_orders, 
	IFNULL(SUM(oi.quantity),0) as quantity,p.price, 
	IFNULL(SUM(oi.quantity)*p.price,0) AS total_price
from products p
	left join order_items oi on oi.product_id=p.id
	left join orders o on o.id=oi.order_id
group by p.name
order by p.name