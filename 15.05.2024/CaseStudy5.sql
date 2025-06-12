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

-- 2.6. What is the percentage of sales for Retail vs Shopify for each month?
WITH monthly_transactions AS (
  SELECT 
    calendar_year, 
    month_number, 
    platform, 
    SUM(CAST(sales AS DECIMAL(18,2))) AS monthly_sales
  FROM clean_weekly_sales
  GROUP BY calendar_year, month_number, platform
)
SELECT 
  calendar_year, 
  month_number, 
  ROUND(100.0 * MAX 
    (CASE 
      WHEN platform = 'Retail' THEN monthly_sales ELSE 0 END) 
    / SUM(monthly_sales), 2) AS retail_percentage,
  ROUND(100.0 * MAX 
    (CASE 
      WHEN platform = 'Shopify' THEN monthly_sales ELSE 0 END)
    / SUM(monthly_sales), 2) AS shopify_percentage
FROM monthly_transactions
GROUP BY calendar_year, month_number
ORDER BY calendar_year, month_number;

-- 2.7. What is the percentage of sales by demographic for each year in the dataset?
WITH demographic_sales AS (
  SELECT 
    calendar_year, 
    demographic, 
    SUM(CAST(sales AS DECIMAL(18,2))) AS yearly_sales
  FROM clean_weekly_sales
  GROUP BY calendar_year, demographic
)

SELECT 
  calendar_year, 
  ROUND(100 * MAX 
    (CASE 
      WHEN demographic = 'Couples' THEN yearly_sales ELSE NULL END)
    / SUM(yearly_sales),2) AS couples_percentage,
  ROUND(100 * MAX 
    (CASE 
      WHEN demographic = 'Families' THEN yearly_sales ELSE NULL END)
    / SUM(yearly_sales),2) AS families_percentage,
  ROUND(100 * MAX 
    (CASE 
      WHEN demographic = 'unknown' THEN yearly_sales ELSE NULL END)
    / SUM(yearly_sales),2) AS unknown_percentage
FROM demographic_sales
GROUP BY calendar_year;

-- 2.8. Which age_band and demographic values contribute the most to Retail sales?
SELECT 
  age_band, 
  demographic, 
  SUM(sales) AS retail_sales,
  ROUND(100.0 * 
    CAST(SUM(sales) AS NUMERIC) 
    / SUM(SUM(sales)) OVER (),
  1) AS contribution_percentage
FROM clean_weekly_sales
WHERE platform = 'Retail'
GROUP BY age_band, demographic
ORDER BY retail_sales DESC;

-- 2.9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? 
-- If not - how would you calculate it instead?
SELECT 
  calendar_year, 
  platform, 
  ROUND(AVG(avg_transaction),0) AS avg_transaction_row, 
  SUM(sales) / sum(transactions) AS avg_transaction_group
FROM clean_weekly_sales
GROUP BY calendar_year, platform
ORDER BY calendar_year, platform;