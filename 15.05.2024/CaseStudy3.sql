-- A. Customer Journey
-- Based off the 8 sample customers provided in the sample from the subscriptions table, 
-- write a brief description about each customer’s onboarding journey.
SELECT s.customer_id, p.plan_id, p.plan_name, s.start_date
FROM plans as p
JOIN subscriptions as s
on p.plan_id = s.plan_id

