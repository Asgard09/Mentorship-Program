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
select c.customer_id, CAST(p.pizza_name as varchar) as pizza_name, count(CAST(p.pizza_name as varchar)) as order_count
from customer_orders as c
join pizza_names as p on c.pizza_id = p.pizza_id
group by c.customer_id, CAST(p.pizza_name as varchar)

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


-- 7. 
-- B. Runner and Customer Experience
-- 4. What was the average distance travelled for each customer?
select customer_id, AVG(TRY_CAST(REPLACE(distance, 'km', '') AS float)) as average_distance
from runner_orders as r
join customer_orders as c on r.order_id = c.order_id
group by customer_id

