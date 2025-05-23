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
