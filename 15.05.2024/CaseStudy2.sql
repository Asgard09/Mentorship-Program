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
CREATE VIEW pizza_details AS (
    SELECT 
        co.order_id,
        co.customer_id,
        co.pizza_id,
        CAST(pn.pizza_name AS NVARCHAR(MAX)) AS pizza_name,
        co.exclusions,
        co.extras
    FROM customer_orders co
    JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
)

CREATE VIEW extras_list AS (
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

SELECT TOP 1 COUNT(*) as purchase_count, TRIM(s.value) AS extra_toppings
FROM extras_list
-- CROSS APPLY STRING_SPLIT(extras, ',') applies the STRING_SPLIT function to each row --> separate 1 row become many rows
-- TRIM --> DELETE SPACE AROUND Ex: ' jj' --> 'jj'
CROSS APPLY STRING_SPLIT(extra_toppings, ',') as s
GROUP BY TRIM(s.value)

-- 3. What was the most common exclusion?
CREATE VIEW exclusions_list AS (
    SELECT 
        pd.order_id,
        pd.customer_id,
        pd.pizza_id,
        pd.pizza_name,
        pd.extras,
        STRING_AGG(CAST(pt.topping_name AS NVARCHAR(MAX)), ', ') AS excluded_toppings
    FROM pizza_details pd
	--  CROSS APPLY STRING_SPLIT(extras, ',') applies the STRING_SPLIT function to each row
    CROSS APPLY STRING_SPLIT(pd.exclusions, ',') s
    JOIN pizza_toppings pt ON TRIM(s.value) = CAST(pt.topping_id AS VARCHAR(10))
    WHERE pd.exclusions IS NOT NULL 
      AND TRIM(pd.exclusions) NOT IN ('', 'null')
    GROUP BY pd.order_id, pd.customer_id, pd.pizza_id, pd.pizza_name, pd.extras
)

SELECT TOP 1 COUNT(*) AS purchase_count, TRIM(s.value) AS excluded_topping
FROM exclusions_list AS e
CROSS APPLY string_split(e.excluded_toppings, ',') AS s
GROUP BY TRIM(s.value)
ORDER BY purchase_count DESC;

-- 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
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

-- 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table 
-- and add a 2x in front of any relevant ingredients
WITH pizza_base_ingredients AS (
    -- Get base ingredients for each pizza type
    SELECT pn.pizza_id, pn.pizza_name, pt.topping_id,
        CAST(pt.topping_name AS NVARCHAR(MAX)) AS topping_name
    FROM pizza_names pn
    JOIN pizza_recipes pr ON pn.pizza_id = pr.pizza_id
    CROSS APPLY STRING_SPLIT(CAST(pr.toppings AS NVARCHAR(MAX)), ',') s
    JOIN pizza_toppings pt ON TRIM(s.value) = CAST(pt.topping_id AS VARCHAR(10))
),
pizza_order_ingredients AS (
    -- Combine base ingredients with extras and exclusions
    SELECT 
        pd.order_id, pd.customer_id, pd.pizza_id,
        pd.pizza_name, pbi.topping_name,
        -- Check if ingredient is excluded
        CASE 
            WHEN el.excluded_toppings IS NOT NULL AND 
                 el.excluded_toppings LIKE '%' + pbi.topping_name + '%' 
            THEN 1 
            ELSE 0 
        END AS is_excluded,
        -- Check if ingredient is also added as extra
        CASE 
            WHEN xl.extra_toppings IS NOT NULL AND 
                 xl.extra_toppings LIKE '%' + pbi.topping_name + '%' 
            THEN 1 
            ELSE 0 
        END AS is_extra
    FROM pizza_details pd
    JOIN pizza_base_ingredients pbi ON pd.pizza_id = pbi.pizza_id
    LEFT JOIN exclusions_list el ON pd.order_id = el.order_id AND pd.pizza_id = el.pizza_id
    LEFT JOIN extras_list xl ON pd.order_id = xl.order_id AND pd.pizza_id = xl.pizza_id
    
    UNION ALL
    
    -- Add extra toppings that aren't in the base recipe
    SELECT 
        pd.order_id,
        pd.customer_id,
        pd.pizza_id,
        pd.pizza_name,
        TRIM(s.value) AS topping_name,
        0 AS is_excluded,
        1 AS is_extra
    FROM pizza_details pd
    JOIN extras_list xl ON pd.order_id = xl.order_id AND pd.pizza_id = xl.pizza_id
    CROSS APPLY STRING_SPLIT(xl.extra_toppings, ',') s
    LEFT JOIN pizza_base_ingredients pbi 
        ON pd.pizza_id = pbi.pizza_id 
        AND TRIM(s.value) = pbi.topping_name
    WHERE pbi.topping_name IS NULL -- Only include extras not in base recipe
),
ingredients_with_counts AS (
    -- Count occurrences of each ingredient in each order
    SELECT 
        order_id,
        pizza_id,
        pizza_name,
        topping_name,
        SUM(CASE WHEN is_excluded = 0 THEN 1 ELSE 0 END) AS ingredient_count
    FROM pizza_order_ingredients
    GROUP BY order_id, pizza_id, pizza_name, topping_name
)

SELECT 
    iwc.order_id,
    iwc.pizza_name + ': ' + 
    STRING_AGG(
        CASE 
            WHEN ingredient_count > 1 THEN '2x' + iwc.topping_name
            ELSE iwc.topping_name
        END, 
        ', '
    ) WITHIN GROUP (ORDER BY iwc.topping_name) AS ingredient_list
FROM ingredients_with_counts iwc
WHERE ingredient_count > 0 -- Only include ingredients that weren't excluded
GROUP BY iwc.order_id, iwc.pizza_id, iwc.pizza_name
ORDER BY iwc.order_id, iwc.pizza_id;

-- 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
WITH delivered_pizzas AS (
    -- Get only pizzas that were successfully delivered
    SELECT 
        c.order_id,
        c.pizza_id,
        CAST(c.exclusions AS NVARCHAR(MAX)) AS exclusions,
        CAST(c.extras AS NVARCHAR(MAX)) AS extras
    FROM customer_orders c
    JOIN runner_orders r ON c.order_id = r.order_id
    WHERE r.pickup_time IS NOT NULL 
      AND (r.cancellation IS NULL OR r.cancellation NOT IN ('Restaurant Cancellation', 'Customer Cancellation'))
),
pizza_ingredients AS (
    -- Get base ingredients for each pizza
    SELECT 
        dp.order_id,
        dp.pizza_id,
        pt.topping_id,
        CAST(pt.topping_name AS NVARCHAR(MAX)) AS topping_name,
        -- Count as 0 if excluded, 1 if not excluded
        CASE 
            WHEN dp.exclusions IS NOT NULL 
                AND dp.exclusions <> ' '
                AND dp.exclusions <> 'null'
                AND EXISTS (
                    SELECT 1 
                    FROM STRING_SPLIT(dp.exclusions, ',') s 
                    WHERE TRIM(s.value) = CAST(pt.topping_id AS VARCHAR(10))
                ) 
            THEN 0 
            ELSE 1 
        END AS is_included
    FROM delivered_pizzas dp
    JOIN pizza_names pn ON dp.pizza_id = pn.pizza_id
    JOIN pizza_recipes pr ON pn.pizza_id = pr.pizza_id
    CROSS APPLY STRING_SPLIT(CAST(pr.toppings AS NVARCHAR(MAX)), ',') s
    JOIN pizza_toppings pt ON TRIM(s.value) = CAST(pt.topping_id AS VARCHAR(10))
    
    UNION ALL
    
    -- Add extra toppings
    SELECT 
        dp.order_id,
        dp.pizza_id,
        pt.topping_id,
        CAST(pt.topping_name AS NVARCHAR(MAX)) AS topping_name,
        1 AS is_included -- Extras are always included
    FROM delivered_pizzas dp
    CROSS APPLY STRING_SPLIT(dp.extras, ',') s
    JOIN pizza_toppings pt ON TRIM(s.value) = CAST(pt.topping_id AS VARCHAR(10))
    WHERE dp.extras IS NOT NULL 
      AND dp.extras <> ' '
      AND dp.extras <> 'null'
      AND TRIM(s.value) <> ''
)

-- Sum up the total quantities of each ingredient
SELECT 
    topping_name AS ingredient,
    SUM(is_included) AS total_quantity
FROM pizza_ingredients
GROUP BY topping_name
ORDER BY total_quantity DESC;
-- D. Pricing and Ratings
-- 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes 
-- how much money has Pizza Runner made so far if there are no delivery fees?
-- Calculate total revenue (Meat Lovers $12, Vegetarian $10)
WITH pizza_prices AS (
    SELECT 1 AS pizza_id, 10 AS price -- Vegetarian pizza price
    UNION ALL
    SELECT 2 AS pizza_id, 12 AS price -- Meat Lovers pizza price
),
successful_orders AS (
    SELECT 
        c.order_id,
        c.pizza_id,
        COUNT(*) AS pizza_count
    FROM customer_orders c
    JOIN runner_orders r ON c.order_id = r.order_id
    WHERE r.cancellation IS NULL OR r.cancellation NOT IN ('Restaurant Cancellation', 'Customer Cancellation')
    GROUP BY c.order_id, c.pizza_id
)

SELECT 
    SUM(so.pizza_count * pp.price) AS total_revenue
FROM successful_orders so
JOIN pizza_prices pp ON so.pizza_id = pp.pizza_id;

-- 2. What if there was an additional $1 charge for any pizza extras and cheese costs $1 extra?
WITH pizza_prices AS (
    SELECT 1 AS pizza_id, 10 AS price -- Vegetarian pizza price
    UNION ALL
    SELECT 2 AS pizza_id, 12 AS price -- Meat Lovers pizza price
),
order_extras_charges AS (
    SELECT 
        c.order_id,
        c.pizza_id,
        -- Base price for the pizza
        pp.price AS base_price,
        -- Count number of extras for each pizza
        CASE 
            WHEN c.extras IS NULL OR TRIM(c.extras) IN ('', 'null') THEN 0
            ELSE LEN(c.extras) - LEN(REPLACE(c.extras, ',', '')) + 1
        END AS extras_count,
        -- Check if cheese (topping_id=4) is added as extra
        CASE 
            WHEN c.extras IS NULL OR TRIM(c.extras) IN ('', 'null') THEN 0
            WHEN c.extras LIKE '%4%' THEN 1
            ELSE 0
        END AS has_extra_cheese
    FROM customer_orders c
    JOIN runner_orders r ON c.order_id = r.order_id
    JOIN pizza_prices pp ON c.pizza_id = pp.pizza_id
    WHERE r.cancellation IS NULL OR r.cancellation NOT IN ('Restaurant Cancellation', 'Customer Cancellation')
)

SELECT 
    SUM(
        base_price + 
        extras_count + -- $1 per extra topping
        has_extra_cheese -- Additional $1 if cheese is added
    ) AS total_revenue_with_extras
FROM order_extras_charges;
