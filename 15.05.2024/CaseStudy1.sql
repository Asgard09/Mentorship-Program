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
select s.customer_id, s.order_date, s.product_id, m.product_name
from [dbo].[sales] as s
join [dbo].[menu] as m on s.product_id = m.product_id
where (s.customer_id, s.order_date) in (
	select customer_id, MIN(order_date)
	from [dbo].[sales] as s
	group by s.customer_id 
);

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select top 1 m.product_name, COUNT(s.product_id) as most_purchased_item
from [dbo].[sales] as s
join [dbo].[menu] as m on s.product_id = m.product_id
group by m.product_name
order by most_purchased_item DESC
