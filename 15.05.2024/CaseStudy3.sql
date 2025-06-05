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
SELECT *
FROM subscriptions as s
JOIN plans as p on s.plan_id = p.plan_id
WHERE p.plan_name = 'churn'
