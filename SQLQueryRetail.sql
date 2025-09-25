USE Northwind;
GO

SELECT *
FROM Categories
;

SELECT *
FROM CustomerCustomerDemo
;

SELECT *
FROM CustomerDemographics
;

SELECT *
FROM Customers
;

SELECT *
FROM Employees
;

SELECT *
FROM Orders
;

SELECT *
FROM [Order Details]
;

SELECT *
FROM Products
;

SELECT *
FROM Region
;

SELECT *
FROM Shippers
;

SELECT *
FROM Suppliers
;

SELECT *
FROM Territories
;
GO 

--Total Sales over time
CREATE OR ALTER VIEW TotalSalesOverTime AS
SELECT 
    DATENAME(month, OrderDate) AS MonthName,
    YEAR(OrderDate) AS Year,
    ROUND(SUM((UnitPrice*(1-Discount)) * Quantity),2) AS TotalSales
FROM Orders 
JOIN [Order Details] ON Orders.OrderID = [Order Details].OrderID
GROUP BY YEAR(OrderDate), DATENAME(month, OrderDate), DATEPART(month, OrderDate)
;
GO

--Top 3 Customers by Units Sold
CREATE OR ALTER VIEW TopCustomersByUnitsSold AS
SELECT TOP 5 Customers.ContactName, SUM([Order Details].Quantity) as TotalUnitsOrdered
FROM Customers
INNER JOIN Orders ON Customers.CustomerID = Orders.CustomerID
INNER JOIN [Order Details] ON Orders.OrderID = [Order Details].OrderID
GROUP BY Customers.ContactName
;
GO

--Top 3 Customers by Units Sold each year
CREATE OR ALTER VIEW TopCustomersByUnitsSoldEachYear AS
WITH TotalMonthlySpend as (
    SELECT Customers.ContactName, YEAR(OrderDate) as YearName,
        SUM([Order Details].Quantity) as CustomerMonthlySpend
    FROM Customers
    INNER JOIN Orders ON Customers.CustomerID = Orders.CustomerID
    INNER JOIN [Order Details] ON Orders.OrderID = [Order Details].OrderID
    GROUP BY Customers.ContactName,YEAR(OrderDate)
),
RankedMonthlySpend as (
    SELECT ContactName, YearName,CustomerMonthlySpend,
    RANK() OVER (PARTITION BY YearName ORDER BY CustomerMonthlySpend DESC) as spendrank
    FROM TotalMonthlySpend
)

SELECT ContactName, YearName,CustomerMonthlySpend
FROM RankedMonthlySpend
WHERE spendrank <=3
;
GO

--Top Product by Units Sold
CREATE OR ALTER VIEW TopProductbyUnitsSold AS
SELECT ProductName, SUM(Quantity) as TotalUnitsSold
FROM [Order Details]
INNER JOIN Products ON [Order Details].ProductID = Products.ProductID
GROUP BY ProductName
;
GO

--Top Products by Revenue
CREATE OR ALTER VIEW TopProductbyRevenue AS
SELECT ProductName, ROUND(SUM(([Order Details].UnitPrice*(1-Discount)) * Quantity),2) AS TotalSales
FROM [Order Details]
INNER JOIN Products ON [Order Details].ProductID = Products.ProductID
GROUP BY ProductName
;
GO

--Top 3 Products by Revenue each year
CREATE OR ALTER VIEW TopProductsEachYearByRevenue AS
WITH YearlySales as (
SELECT Products.ProductName, YEAR(OrderDate) as YearName, ROUND(SUM(([Order Details].UnitPrice*(1-Discount)) * Quantity),2) AS TotalSales
FROM [Order Details]
INNER JOIN Products ON [Order Details].ProductID = Products.ProductID
INNER JOIN Orders ON [Order Details].OrderID = Orders.OrderID
GROUP BY ProductName, YEAR(OrderDate)
),
YearlySalesRank as (
SELECT ProductName, YearName, TotalSales, 
    RANK() OVER(PARTITION BY YearName ORDER BY TotalSales DESC) as productrank
FROM YearlySales
)
SELECT ProductName, YearName, TotalSales
FROM YearlySalesRank
WHERE productrank <= 3
;
GO

--Top 3 Products by Units sold each year
CREATE OR ALTER VIEW TopProductsEachYearByUnitsSold AS
WITH YearlyUnits as (
SELECT Products.ProductName, YEAR(OrderDate) as YearName, SUM(Quantity) AS TotalUnitsSold
FROM [Order Details]
INNER JOIN Products ON [Order Details].ProductID = Products.ProductID
INNER JOIN Orders ON [Order Details].OrderID = Orders.OrderID
GROUP BY ProductName, YEAR(OrderDate)
),
YearlyUnitsRank as (
SELECT ProductName, YearName, TotalUnitsSold, 
    RANK() OVER(PARTITION BY YearName ORDER BY TotalUnitsSold DESC) as productrank
FROM YearlyUnits
)
SELECT ProductName, YearName, TotalUnitsSold
FROM YearlyUnitsRank
WHERE productrank <= 3
;
GO

--Top Categories by Sales
CREATE OR ALTER VIEW TopCategoriesbySales AS
SELECT CategoryName, ROUND(SUM(([Order Details].UnitPrice*(1-Discount)) * Quantity),2) AS TotalSales
FROM Products
INNER JOIN Categories ON Products.CategoryID = Categories.CategoryID
INNER JOIN [Order Details] ON Products.ProductID = [Order Details].ProductID
GROUP BY CategoryName
;
GO

--Top Categories by Units Sold
CREATE OR ALTER VIEW TopCategoriesbyUnitsSold AS
SELECT CategoryName, SUM(Quantity) AS TotalUnits
FROM Products
INNER JOIN Categories ON Products.CategoryID = Categories.CategoryID
INNER JOIN [Order Details] ON Products.ProductID = [Order Details].ProductID
GROUP BY CategoryName
;
GO

-- Top Suppliers
CREATE OR ALTER VIEW TopSuppliers AS
SELECT CompanyName, SUM(Quantity) as TotalGoodsSupplied
FROM Suppliers
INNER JOIN Products ON Suppliers.SupplierID = Products.SupplierID
INNER JOIN [Order Details] ON Products.ProductID = [Order Details].ProductID
GROUP BY CompanyName
;
GO

--Items Low in Stock
CREATE OR ALTER VIEW LowStock AS
SELECT ProductName, UnitsInStock, CategoryName
FROM Products
INNER JOIN Categories ON Products.CategoryID = Categories.CategoryID
WHERE UnitsInStock < 40
;
GO

--Items High in Stock
CREATE OR ALTER VIEW HighStock AS
SELECT ProductName, UnitsInStock, CategoryName
FROM Products
INNER JOIN Categories ON Products.CategoryID = Categories.CategoryID
WHERE UnitsInStock >= 40
;
GO

--Stock vs Sales Ratio
CREATE OR ALTER VIEW StockvsSales AS
WITH Sales AS (
    SELECT 
        c.CategoryName,
        p.ProductName,
        SUM(p.UnitsInStock) AS TotalStock,
        SUM(od.Quantity) AS UnitsSold
    FROM Products p
    JOIN [Order Details] od ON p.ProductID = od.ProductID
    JOIN Categories c ON p.CategoryID = c.CategoryID
    GROUP BY c.CategoryName, p.ProductName
)
SELECT 
    CategoryName,
    ProductName,
    TotalStock,
    UnitsSold,
    ROUND(CAST(TotalStock AS FLOAT) / NULLIF(UnitsSold, 0), 2) AS StockToSalesRatio,
    ROUND(
        UnitsSold * 1.0 / SUM(UnitsSold) OVER (PARTITION BY CategoryName), 
        3
    ) * 100 AS PctOfCategorySales
FROM Sales;

