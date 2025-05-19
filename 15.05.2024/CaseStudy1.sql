-- 1. What is the total amount each customer spent at the restaurant?
select s.[customer_id], SUM(m.[price]) as totalAmount
from [dbo].[sales] as s
join [dbo].[menu] as m on s.[product_id] = m.[product_id]
group by s.[customer_id];

-- 2. How many days has each customer visited the restaurant?
select [customer_id], COUNT(DISTINCT([order_date])) as visisted_date
from [dbo].[sales]
group by [customer_id];

-- 3. What was the first item from the menu purchased by each customer?
-- for first purchased not in menu
select customer_id,MIN(product_name) as first_purchased, MIN(order_date) as time_to_buy
from sales s
join menu m on s.product_id = m.product_id
group by customer_id;

-- ROW_NUMBER() là một window function dùng để đánh số thứ tự từng dòng trong một nhóm (PARTITION) 
-- theo thứ tự chỉ định.
select customer_id, m.product_name, order_date
from(
	select s.customer_id, s.order_date, s.product_id,
	row_number() over(
		partition by s.customer_id
		order by s.order_date
	) as rn
	from sales as s
) as r
join menu as m on r.product_id = m.product_id
where rn = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select top 1 m.product_name, COUNT(s.product_id) as most_purchased_item
from [dbo].[sales] as s
join [dbo].[menu] as m on s.product_id = m.product_id
group by m.product_name
order by most_purchased_item DESC

-- 5. Which item was the most popular for each customer?
WITH most_popular AS (
  SELECT sales.customer_id, menu.product_name, COUNT(menu.product_id) AS order_count,
  dense_rank() OVER (
	PARTITION BY sales.customer_id 
    ORDER BY COUNT(sales.customer_id) DESC
  ) AS rank
  FROM [dbo].[menu]
  INNER JOIN [dbo].[sales] ON menu.product_id = sales.product_id
  GROUP BY sales.customer_id, menu.product_name
)

SELECT 
  customer_id, 
  product_name, 
  order_count
FROM most_popular 
WHERE rank = 1;



