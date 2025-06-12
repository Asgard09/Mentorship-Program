-- 1. Data Cleansing Steps
SELECT
  CONVERT(DATE, week_date, 3) AS week_date,
  DATEPART(week, CONVERT(DATE, week_date, 3)) AS week_number,
  DATEPART(month, CONVERT(DATE, week_date, 3)) AS month_number,
  DATEPART(year, CONVERT(DATE, week_date, 3)) AS calendar_year,
  region, 
  platform, 
  segment,
  CASE 
    WHEN RIGHT(segment, 1) = '1' THEN 'Young Adults'
    WHEN RIGHT(segment, 1) = '2' THEN 'Middle Aged'
    WHEN RIGHT(segment, 1) IN ('3', '4') THEN 'Retirees'
    ELSE 'unknown' 
  END AS age_band,
  CASE 
    WHEN LEFT(segment, 1) = 'C' THEN 'Couples'
    WHEN LEFT(segment, 1) = 'F' THEN 'Families'
    ELSE 'unknown' 
  END AS demographic,
  transactions,
  ROUND(CAST(sales AS DECIMAL(18,2)) / transactions, 2) AS avg_transaction,
  sales
INTO clean_weekly_sales
FROM weekly_sales;

-- 2. Data Exploration
-- 2.1. What day of the week is used for each 'week_date' value?
SELECT DISTINCT DATENAME(WEEKDAY, CONVERT(DATE, week_date, 103)) as DayOfWeek
FROM clean_weekly_sales;

-- 2.2. What range of week numbers are missing from the dataset?
WITH week_number_cte AS (
  SELECT 1 AS week_number
  UNION ALL
  SELECT week_number + 1
  FROM week_number_cte
  WHERE week_number < 52
)
  
SELECT DISTINCT week_no.week_number
FROM week_number_cte AS week_no
LEFT JOIN clean_weekly_sales AS sales
  ON week_no.week_number = sales.week_number
WHERE sales.week_number IS NULL

-- 2.3. How many total transactions were there for each year in the dataset?
SELECT calendar_year, SUM(transactions) AS total_transaction
FROM clean_weekly_sales
GROUP BY calendar_year

-- 2.4. What is the total sales for each region for each month?
SELECT 
  month_number, 
  region, 
  SUM(sales) AS total_sales
FROM clean_weekly_sales
GROUP BY month_number, region
ORDER BY month_number, region;

-- 2.5. What is the total count of transactions for each platform?
SELECT 
  platform, 
  SUM(transactions) AS total_transactions
FROM clean_weekly_sales
GROUP BY platform;
