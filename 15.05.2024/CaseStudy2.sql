-- 1. How many pizzas were ordered?
select [pizza_id], COUNT([order_id]) as number_of_orders
from [dbo].[customer_orders]
group by [pizza_id]

-- 2. How many unique customer orders were made?
select [customer_id] , COUNT(DISTINCT [order_id]) as number_of_orders
from [dbo].[customer_orders]
group by [customer_id]

-- 3. How many successful orders were delivered by each runner?
