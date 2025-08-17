📊 E-Commerce Sales Data Analysis - README

## 🔍 Overview

**Project Title:** E-Commerce Sales Analysis

**Level:** Intermediate / SQL Analytics

This project demonstrates end-to-end **SQL-based data analysis** on an e-commerce sales dataset. It focuses on **data cleaning, validation, and business insights** using advanced SQL queries.

**Objectives:**

* Build a structured database for sales records.
* Clean and validate raw sales data.
* Perform advanced analytics to extract actionable insights.

## 🗄️ Database Details

**Database Name:** ECommerceDB
**Main Table:** Sales

**Table Schema:**

| Column      | Type     | Description                  |
| ----------- | -------- | ---------------------------- |
| InvoiceNo   | TEXT     | Unique invoice identifier    |
| StockCode   | TEXT     | Product stock code           |
| Description | TEXT     | Product description          |
| Quantity    | INT      | Number of units sold         |
| InvoiceDate | DATETIME | Date and time of transaction |
| UnitPrice   | DECIMAL  | Price per unit               |
| CustomerID  | TEXT     | Unique customer identifier   |
| Country     | TEXT     | Customer's country           |

## ⚙️ Setup Instructions

1. **Create Database:**

```sql
CREATE DATABASE IF NOT EXISTS ECommerceDB;
USE ECommerceDB;
```

2. **Load Sales Table** with your dataset.
3. **Ensure Correct Column Datatypes:**

```sql
ALTER TABLE Sales
MODIFY COLUMN UnitPrice DECIMAL(10,2),
MODIFY COLUMN InvoiceDate DATETIME;
```

## 🧹 Data Cleaning Steps

* Checked for **NULL values** in key columns.
* Removed rows with **negative or zero Quantity/UnitPrice**.
* Filtered invalid **InvoiceDate** and **StockCode** entries.
* Removed **duplicate records** using `ROW_NUMBER()` for accurate analytics.

## 📈 Analysis Highlights

* **Daily Sales:** Total, cumulative, and 7-day moving average.
* **Sales Growth:** Day-over-Day (DoD) growth percentages.
* **Country Insights:** Stored procedure `GetCountrySales` summarizes sales per country.
* **Top Performers:** Top countries and top 3 customers per country by total sales.
* **Business Insights:** Customer segmentation and trend analysis.

## 🚀 Getting Started

1. Clone or download this repository.
2. Open SQL scripts in MySQL Workbench or preferred SQL client.
3. Import your sales dataset.
4. Run queries to clean data and perform analytics.

## 💡 Notes & Recommendations

* Adjust **date formats** and data types based on your RDBMS.
* Use **indexes** to improve performance for large datasets.
* Expand **validation rules** as needed for additional data quality.

## 📝 License

This project is intended for educational and analytical purposes.

## 📬 Contact

Reach out to the project maintainer for questions or suggestions.

**Happy Analyzing!**
