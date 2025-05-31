-- 1. How many pizzas were ordered?
select [pizza_id], COUNT([order_id]) as number_of_orders
from [dbo].[customer_orders]
group by [pizza_id]

-- 2. How many unique customer orders were made?
select [customer_id] , COUNT(DISTINCT [order_id]) as number_of_orders
from [dbo].[customer_orders]
group by [customer_id]

-- 3. How many successful orders were delivered by each runner? --> distance != null
select runner_id, COUNT(order_id) AS successful_orders
from runner_orders
where TRY_CAST(REPLACE(distance, 'km', '') AS float) is not null
GROUP BY runner_id;

-- 4. How many of each type of pizza was delivered?
SELECT CAST(p.pizza_name as varchar) as pizza_name, COUNT(c.pizza_id) AS delivered_pizza_count
FROM customer_orders AS c
JOIN runner_orders AS r
  ON c.order_id = r.order_id
JOIN pizza_names AS p
  ON c.pizza_id = p.pizza_id
WHERE TRY_CAST(REPLACE(distance, 'km', '') AS float) is not null
GROUP BY CAST(p.pizza_name as varchar);

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
-- Turning row values into columns
SELECT customer_id, [Vegetarian], [Meatlovers]
FROM (
	SELECT c.customer_id,
		CASE 
			WHEN pn.pizza_id = 1 THEN 'Vegetarian'
			ELSE 'Meatlovers'
		END AS pizza_type
	FROM customer_orders as c 
	JOIN pizza_names as pn ON c.pizza_id = c.pizza_id
) AS source
PIVOT (
	COUNT(pizza_type)
	FOR pizza_type IN([Vegetarian], [Meatlovers])
) as pivot_table;

-- 6. What was the maximum number of pizzas delivered in a single order?
WITH pizza_count_cte AS
(
  SELECT 
    c.order_id, 
    COUNT(c.pizza_id) AS pizza_per_order
  FROM customer_orders AS c
  JOIN runner_orders AS r
    ON c.order_id = r.order_id
  WHERE TRY_CAST(REPLACE(distance, 'km', '') AS float) != 0
  GROUP BY c.order_id
)

SELECT 
  MAX(pizza_per_order) AS pizza_count
FROM pizza_count_cte;

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
with delivered_pizzas_cte as(
	select c.customer_id, 
		case 
			when c.exclusions <> ' ' OR c.extras <> ' ' THEN 1
			else 0
		end as at_least_1_change,
		case
			when c.exclusions = ' ' AND c.extras = ' ' THEN 1 
			else 0
		end as no_change
	from customer_orders AS c
	JOIN runner_orders AS r ON c.order_id = r.order_id
	WHERE TRY_CAST(REPLACE(r.distance, 'km', '') AS float) != 0
)

select customer_id, SUM(at_least_1_change) as at_least_1_change, SUM(no_change) as no_change
from delivered_pizzas_cte
group by customer_id

-- 8. How many pizzas were delivered that had both exclusions and extras?
with both_exclusions_and_extras as(
	select 
		case	
			when exclusions IS NOT NULL AND extras IS NOT NULL THEN 1
			else 0
		end as pizza_count
	from customer_orders as c
	join runner_orders as r on c.order_id = r.order_id
	WHERE TRY_CAST(REPLACE(r.distance, 'km', '') AS float) != 0
	AND exclusions <> ' ' 
	AND extras <> ' '
)

select SUM(pizza_count) as pizza_count_w_exclusions_extras
from both_exclusions_and_extras

-- 9. What was the total volume of pizzas ordered for each hour of the day?
SELECT 
    DATEPART(HOUR, order_time) AS Hour,
    COUNT(order_id) AS Number_of_pizzas_ordered,
    ROUND(100.0 * COUNT(order_id) / SUM(COUNT(order_id)) OVER (), 2) AS Volume_of_pizzas_ordered
FROM customer_orders
GROUP BY DATEPART(HOUR, order_time)
ORDER BY [Hour];

-- 10. What was the volume of orders for each day of the week?
SELECT 
    DATEPART(WEEKDAY, order_time) AS [Day Of Week],
    COUNT(order_id) AS [Number of pizzas ordered],
    ROUND(100.0 * COUNT(order_id) / SUM(COUNT(order_id)) OVER (), 2) AS [Volume of pizzas ordered]
FROM customer_orders
GROUP BY DATEPART(WEEKDAY, order_time)
ORDER BY [Number of pizzas ordered] DESC;

-- B. Runner and Customer Experience
-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
select DATEPART(WEEK, registration_date) as registartion_week,
	COUNT(runner_id) as runner_signup
from runners
group by DATEPART(WEEK, registration_date)
-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT 
    r.runner_id,
    ROUND(AVG(DATEDIFF(MINUTE, c.order_time, r.pickup_time) * 1.0), 2) AS avg_runner_pickup_time
FROM runner_orders AS r
INNER JOIN customer_orders AS c ON r.order_id = c.order_id
WHERE r.cancellation IS NULL
GROUP BY r.runner_id;
-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
WITH order_count_cte AS (
	SELECT 
        r.order_id,
        COUNT(pizza_id) AS pizzas_order_count,
        DATEDIFF(MINUTE, c.order_time, r.pickup_time) AS prep_time
	FROM runner_orders AS r
	JOIN customer_orders AS c ON r.order_id = c.order_id
	WHERE r.cancellation IS NULL
	GROUP BY r.order_id, c.order_time, r.pickup_time
)
SELECT 
    pizzas_order_count,
    ROUND(AVG(prep_time * 1.0), 2) AS avg_prep_time
FROM order_count_cte
GROUP BY pizzas_order_count;

-- 4. What was the average distance travelled for each customer?
select customer_id, AVG(TRY_CAST(REPLACE(distance, 'km', '') AS float)) as average_distance
from runner_orders as r
join customer_orders as c on r.order_id = c.order_id
group by customer_id

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT MIN(duration) as  minimum_duration,
       MAX(duration) AS maximum_duration,
       MAX(duration) - MIN(duration) AS maximum_difference
FROM runner_orders;

-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT runner_id,
       distance AS distance_km,
       round(duration/60, 2) AS duration_hr,
       round(distance*60/duration, 2) AS average_speed
FROM runner_orders
WHERE cancellation IS NULL
ORDER BY runner_id;

-- 7. What is the successful delivery percentage for each runner?
SELECT runner_id,
       COUNT(pickup_time) AS delivered_orders,
       COUNT(*) AS total_orders,
       ROUND(100.0 * COUNT(pickup_time) / COUNT(*), 2) AS delivery_success_percentage
FROM runner_orders
GROUP BY runner_id
ORDER BY runner_id;

-- C. Ingredient Optimisation
-- 1. What are the standard ingredients for each pizza?
select *
from pizza_recipes

-- 2. What was the most commonly added extra?
WITH split_extras AS (
	-- Removes any leading or trailing spaces from each value after splitting
    SELECT value AS extra_topping
    FROM customer_orders
	--  CROSS APPLY STRING_SPLIT(extras, ',') applies the STRING_SPLIT function to each row
    CROSS APPLY STRING_SPLIT(extras, ',')
    WHERE extras IS NOT NULL 
      AND TRIM(extras) != 'null'
      AND TRIM(extras) != ''
),
extra_count_cte AS(
	SELECT extra_topping, COUNT(*) AS purchase_count
	FROM split_extras 
	GROUP BY extra_topping
)

SELECT top 1 p.topping_name, purchase_count
FROM extra_count_cte as e
JOIN pizza_toppings as p on e.extra_topping = p.topping_id
ORDER BY purchase_count DESC

-- 3. What was the most common exclusion?
WITH split_exclusion AS (
	-- Removes any leading or trailing spaces from each value after splitting
    SELECT value AS exclusion_topping
    FROM customer_orders
	--  CROSS APPLY STRING_SPLIT(extras, ',') applies the STRING_SPLIT function to each row
    CROSS APPLY STRING_SPLIT(exclusions, ',')
    WHERE exclusions IS NOT NULL 
      AND TRIM(exclusions) != 'null'
      AND TRIM(exclusions) != ''
),
exclusion_count_cte AS(
	SELECT exclusion_topping, COUNT(*) AS purchase_count
	FROM split_exclusion
	GROUP BY exclusion_topping
)

SELECT top 1 p.topping_name, purchase_count
FROM exclusion_count_cte as e
JOIN pizza_toppings as p on e.exclusion_topping = p.topping_id
ORDER BY purchase_count DESC

-- 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
WITH pizza_details AS (
    SELECT 
        co.order_id,
        co.customer_id,
        co.pizza_id,
        CAST(pn.pizza_name AS NVARCHAR(MAX)) AS pizza_name,
        co.exclusions,
        co.extras
    FROM customer_orders co
    JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
),
exclusions_list AS (
    SELECT 
        pd.order_id,
        pd.customer_id,
        pd.pizza_id,
        pd.pizza_name,
        pd.extras,
        STRING_AGG(CAST(pt.topping_name AS NVARCHAR(MAX)), ', ') AS excluded_toppings
    FROM pizza_details pd
    CROSS APPLY STRING_SPLIT(pd.exclusions, ',') s
    JOIN pizza_toppings pt ON TRIM(s.value) = CAST(pt.topping_id AS VARCHAR(10))
    WHERE pd.exclusions IS NOT NULL 
      AND TRIM(pd.exclusions) NOT IN ('', 'null')
    GROUP BY pd.order_id, pd.customer_id, pd.pizza_id, pd.pizza_name, pd.extras
),
extras_list AS (
    SELECT 
        pd.order_id,
        pd.customer_id,
        pd.pizza_id,
        pd.pizza_name,
        pd.exclusions,
        STRING_AGG(CAST(pt.topping_name AS NVARCHAR(MAX)), ', ') AS extra_toppings
    FROM pizza_details pd
    CROSS APPLY STRING_SPLIT(pd.extras, ',') s
    JOIN pizza_toppings pt ON TRIM(s.value) = CAST(pt.topping_id AS VARCHAR(10))
    WHERE pd.extras IS NOT NULL 
      AND TRIM(pd.extras) NOT IN ('', 'null')
    GROUP BY pd.order_id, pd.customer_id, pd.pizza_id, pd.pizza_name, pd.exclusions
)
SELECT 
    pd.order_id,
    pd.customer_id,
    CASE 
        WHEN el.excluded_toppings IS NULL AND xl.extra_toppings IS NULL 
            THEN pd.pizza_name
        WHEN el.excluded_toppings IS NULL 
            THEN CAST(pd.pizza_name AS NVARCHAR(MAX)) + N' - Extra ' + CAST(xl.extra_toppings AS NVARCHAR(MAX))
        WHEN xl.extra_toppings IS NULL 
            THEN CAST(pd.pizza_name AS NVARCHAR(MAX)) + N' - Exclude ' + CAST(el.excluded_toppings AS NVARCHAR(MAX))
        ELSE CAST(pd.pizza_name AS NVARCHAR(MAX)) + N' - Exclude ' + CAST(el.excluded_toppings AS NVARCHAR(MAX)) + N' - Extra ' + CAST(xl.extra_toppings AS NVARCHAR(MAX))
    END AS order_item
FROM pizza_details pd
LEFT JOIN exclusions_list el 
    ON pd.order_id = el.order_id AND pd.pizza_id = el.pizza_id
LEFT JOIN extras_list xl 
    ON pd.order_id = xl.order_id AND pd.pizza_id = xl.pizza_id
ORDER BY pd.order_id;