-- ===========================================
-- E-Commerce Sales Data Analysis Using SQL
-- ===========================================

-- ===========================================
-- STEP 1: View existing databases
-- ===========================================
SHOW DATABASES;

-- ===========================================
-- STEP 2: Create and use the database
-- (Run CREATE only if database does not exist)
-- ===========================================
CREATE DATABASE IF NOT EXISTS ECommerceDB;
USE ECommerceDB;

-- ===========================================
-- STEP 3: Show tables in the database
-- ===========================================
SHOW TABLES;

-- ===========================================
-- STEP 4: Preview the Sales table (first 10 records)
-- ===========================================
SELECT *
FROM Sales
LIMIT 10;

-- ===========================================
-- STEP 5: Ensure correct column datatypes
-- ===========================================
ALTER TABLE Sales
MODIFY COLUMN UnitPrice DECIMAL(10,2),
MODIFY COLUMN InvoiceDate DATETIME;

-- ===========================================
-- STEP 6: Data Quality Check – Identify missing values
-- ===========================================

-- 6a. Check NULLs individually for important columns
SELECT COUNT(*) AS MissingInvoiceNo
FROM Sales
WHERE InvoiceNo IS NULL;

SELECT COUNT(*) AS MissingStockCode
FROM Sales
WHERE StockCode IS NULL;

SELECT COUNT(*) AS MissingDescription
FROM Sales
WHERE Description IS NULL;

SELECT COUNT(*) AS MissingInvoiceDate
FROM Sales
WHERE InvoiceDate IS NULL;

SELECT COUNT(*) AS MissingUnitPrice
FROM Sales
WHERE UnitPrice IS NULL;

SELECT COUNT(*) AS MissingCustomerID
FROM Sales
WHERE CustomerID IS NULL;

SELECT COUNT(*) AS MissingCountry
FROM Sales
WHERE Country IS NULL;

-- 6b. Combined summary of missing values
SELECT
    SUM(CASE WHEN InvoiceNo IS NULL THEN 1 ELSE 0 END) AS MissingInvoiceNo,
    SUM(CASE WHEN StockCode IS NULL THEN 1 ELSE 0 END) AS MissingStockCode,
    SUM(CASE WHEN Description IS NULL THEN 1 ELSE 0 END) AS MissingDescription,
    SUM(CASE WHEN InvoiceDate IS NULL THEN 1 ELSE 0 END) AS MissingInvoiceDate,
    SUM(CASE WHEN UnitPrice IS NULL THEN 1 ELSE 0 END) AS MissingUnitPrice,
    SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS MissingCustomerID,
    SUM(CASE WHEN Country IS NULL THEN 1 ELSE 0 END) AS MissingCountry
FROM Sales;

-- ===========================================
-- STEP 7: Data Cleaning – Remove invalid or bad data
-- ===========================================
SET SQL_SAFE_UPDATES = 0;

-- Remove rows with missing CustomerID
DELETE FROM Sales
WHERE CustomerID IS NULL;

-- Remove rows with negative or zero Quantity or UnitPrice
DELETE FROM Sales
WHERE Quantity <= 0 OR UnitPrice <= 0;

-- Remove rows where InvoiceDate is invalid text
DELETE FROM Sales
WHERE InvoiceDate REGEXP '^[a-zA-Z]';

-- Remove rows with invalid StockCode (only letters)
DELETE FROM Sales
WHERE StockCode REGEXP '^[a-zA-Z]+$';

SET SQL_SAFE_UPDATES = 1;

-- ===========================================
-- STEP 8: Outlier Detection
-- Identify unusually large Quantity or UnitPrice
-- ===========================================
SELECT *
FROM Sales
WHERE Quantity > 10000 OR UnitPrice > 10000;

-- ===========================================
-- STEP 9: Duplicate Check
-- Identify duplicate records based on key columns
-- ===========================================
SELECT InvoiceNo, StockCode, CustomerID, COUNT(*) AS DupCount
FROM Sales
GROUP BY InvoiceNo, StockCode, CustomerID
HAVING COUNT(*) > 1;

-- ===========================================
-- STEP 10: Duplicate Removal (MySQL 8.0+)
-- Keep the first occurrence of duplicates
-- ===========================================
WITH Ranked AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY InvoiceNo, StockCode, CustomerID, InvoiceDate, Quantity
               ORDER BY InvoiceNo
           ) AS rn
    FROM Sales
)
DELETE FROM Sales
WHERE (InvoiceNo, StockCode, CustomerID, InvoiceDate, Quantity) IN (
    SELECT InvoiceNo, StockCode, CustomerID, InvoiceDate, Quantity
    FROM Ranked
    WHERE rn > 1
);

-- ===========================================
-- STEP 11: Verify Cleaning
-- Ensure no missing CustomerID remains
-- ===========================================
SELECT *
FROM Sales
WHERE CustomerID IS NULL OR CustomerID = '';

-- ===========================================
-- STEP 12: Sales Analytics
-- ===========================================

-- 12a. Total sales by date (daily revenue)
SELECT DATE(InvoiceDate) AS OrderDate,
       SUM(Quantity * UnitPrice) AS TotalSales
FROM Sales
GROUP BY DATE(InvoiceDate)
ORDER BY OrderDate;

-- 12b. Day-over-Day sales growth
WITH daily_sales AS (
    SELECT DATE(InvoiceDate) AS Day,
           SUM(Quantity * UnitPrice) AS TotalSales
    FROM Sales
    GROUP BY DATE(InvoiceDate)
)
SELECT Day,
       TotalSales,
       LAG(TotalSales) OVER (ORDER BY Day) AS PreviousDaySales,
       ROUND(
           ((TotalSales - LAG(TotalSales) OVER (ORDER BY Day)) 
           / LAG(TotalSales) OVER (ORDER BY Day)) * 100, 2
       ) AS DoDGrowthPercentage
FROM daily_sales
ORDER BY Day;

-- 12c. Cumulative daily sales
WITH daily_sales AS (
    SELECT DATE(InvoiceDate) AS Day,
           SUM(Quantity * UnitPrice) AS DailySales
    FROM Sales
    GROUP BY DATE(InvoiceDate)
)
SELECT Day,
       DailySales,
       SUM(DailySales) OVER (ORDER BY Day) AS CumulativeSales
FROM daily_sales
ORDER BY Day;

-- 12d. 7-day moving average of daily sales
WITH daily_sales AS (
    SELECT DATE(InvoiceDate) AS Day,
           SUM(Quantity * UnitPrice) AS DailySales
    FROM Sales
    GROUP BY DATE(InvoiceDate)
)
SELECT Day,
       DailySales,
       AVG(DailySales) OVER(ORDER BY Day ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS MovingAvg_7days
FROM daily_sales
ORDER BY Day;

-- ===========================================
-- STEP 13: Country-Level Sales Analysis
-- ===========================================

-- 13a. Stored Procedure: Get sales summary for a given country
DELIMITER //
CREATE PROCEDURE GetCountrySales(IN countryName VARCHAR(50))
BEGIN
    SELECT COUNT(DISTINCT CustomerID) AS TotalCustomers,
           Country,
           SUM(Quantity * UnitPrice) AS TotalSales,
           AVG(Quantity * UnitPrice) AS AvgSales,
           CASE 
               WHEN SUM(Quantity * UnitPrice) > 10000 THEN 'High'
               WHEN SUM(Quantity * UnitPrice) BETWEEN 5000 AND 10000 THEN 'Medium'
               ELSE 'Low'
           END AS LevelOfSales,
           DENSE_RANK() OVER (ORDER BY SUM(Quantity * UnitPrice) DESC) AS Ranking
    FROM Sales
    WHERE Country = countryName
    GROUP BY Country;
END;
//
CALL GetCountrySales('United Kingdom');

-- 13b. Top countries by total sales + percentage contribution
SELECT Country,
       SUM(Quantity * UnitPrice) AS TotalSales,
       CONCAT(ROUND(SUM(Quantity * UnitPrice) / (SELECT SUM(Quantity * UnitPrice) FROM Sales) * 100, 2), '%') AS PercentContribution
FROM Sales
GROUP BY Country
ORDER BY TotalSales DESC
LIMIT 10;

-- 13c. Top 3 customers per country based on total purchase amount
SELECT CustomerID,
       Country,
       TotalSales,
       Ranking
FROM (
    SELECT CustomerID,
           Country,
           SUM(Quantity * UnitPrice) AS TotalSales,
           DENSE_RANK() OVER (PARTITION BY Country ORDER BY SUM(Quantity * UnitPrice) DESC) AS Ranking
    FROM Sales
    GROUP BY CustomerID, Country
) AS CustomerSales
WHERE Ranking <= 3
ORDER BY Country, Ranking;
-- ===========================================
