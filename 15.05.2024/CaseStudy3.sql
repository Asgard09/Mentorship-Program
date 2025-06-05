-- A. Customer Journey
-- Based off the 8 sample customers provided in the sample from the subscriptions table, 
-- write a brief description about each customer’s onboarding journey.
SELECT s.customer_id, p.plan_id, p.plan_name, s.start_date
FROM plans as p
JOIN subscriptions as s
on p.plan_id = s.plan_id

-- B. Data Analysis Questions
-- 1. How many customers has Foodie-Fi ever had?
SELECT COUNT(DISTINCT s.customer_id) as count_customers
FROM subscriptions as s

-- 2. What is the monthly distribution of trial plan start_date values for our dataset 
-- use the start of the month as the group by value
SELECT DATEPART(month, s.start_date) AS month_date, DATENAME(month, s.start_date) as month_name,  COUNT(*) as count
FROM subscriptions as s
JOIN plans as p on s.plan_id = p.plan_id
WHERE p.plan_name = 'trial'
GROUP BY DATENAME(month, s.start_date), DATEPART(month, s.start_date)
ORDER BY DATEPART(month, s.start_date)

-- 3. What plan start_date values occur after the year 2020 for our dataset? 
-- Show the breakdown by count of events for each plan_name.
SELECT p.plan_id, p.plan_name, COUNT(s.customer_id) as num_of_events
FROM subscriptions as s
JOIN plans as p on s.plan_id = p.plan_id
WHERE s.start_date > '2021-01-01'
GROUP BY p.plan_id, p.plan_name
ORDER BY p.plan_id

-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
SELECT COUNT(DISTINCT s.customer_id) AS customer_count, 
	(COUNT(DISTINCT s.customer_id) * 100)/(SELECT COUNT(customer_id) FROM subscriptions) AS churn_percentage
FROM subscriptions as s
JOIN plans as p on s.plan_id = p.plan_id
WHERE p.plan_name = 'churn'

-- 5. How many customers have churned straight after their initial free trial 
-- what percentage is this rounded to the nearest whole number?
WITH ranked_cte AS (
  SELECT 
    sub.customer_id, 
    plans.plan_id, 
	plans.plan_name,
	  ROW_NUMBER() OVER (
      PARTITION BY sub.customer_id 
      ORDER BY sub.start_date) AS row_num
  FROM subscriptions AS sub
  JOIN plans 
    ON sub.plan_id = plans.plan_id
)

SELECT (COUNT(r1.customer_id)*100)/(SELECT COUNT(customer_id) FROM subscriptions) AS churn_percentage
FROM ranked_cte as r1
JOIN ranked_cte as r2 on r1.customer_id = r2.customer_id
AND r2.row_num = r1.row_num + 1
WHERE r1.plan_id = 0 AND r2.plan_id = 4

-- 6. What is the number and percentage of customer plans after their initial free trial?
WITH next_plans AS (
  SELECT 
    customer_id, 
    plan_id, 
	-- LEAD() use to query the next row 
    LEAD(plan_id) OVER(
      PARTITION BY customer_id 
      ORDER BY plan_id) as next_plan_id
  FROM subscriptions
)

SELECT 
  next_plan_id AS plan_id, 
  COUNT(customer_id) AS converted_customers,
  ROUND(100 * COUNT(customer_id)/ (SELECT COUNT(DISTINCT customer_id) FROM subscriptions),1) AS conversion_percentage
FROM next_plans
WHERE next_plan_id IS NOT NULL 
  AND plan_id = 0
GROUP BY next_plan_id
ORDER BY next_plan_id;

-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
WITH next_dates AS (
  SELECT
    customer_id,
    plan_id,
  	start_date,
    LEAD(start_date) OVER (
      PARTITION BY customer_id
      ORDER BY start_date
    ) AS next_date
  FROM subscriptions
  WHERE start_date <= '2020-12-31'
)

SELECT
	plan_id, 
	COUNT(DISTINCT customer_id) AS customers,
  ROUND(100.0 * 
    COUNT(DISTINCT customer_id)
    / (SELECT COUNT(DISTINCT customer_id) 
      FROM subscriptions)
  ,1) AS percentage
FROM next_dates
WHERE next_date IS NULL
GROUP BY plan_id;