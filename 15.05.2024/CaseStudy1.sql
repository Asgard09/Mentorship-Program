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
with first_purchased_in_menu as(
	select s.customer_id, s.product_id, m.product_name, s.order_date,
		ROW_NUMBER() over(
			partition by (s.customer_id)
			order by (s.order_date)
		) as rank
	from sales s
	join menu m on s.product_id = m.product_id
)

select customer_id, product_name, order_date
from first_purchased_in_menu
where rank = 1;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select top 1 m.product_name, COUNT(s.product_id) as most_purchased_item
from [dbo].[sales] as s
join [dbo].[menu] as m on s.product_id = m.product_id
group by m.product_name
order by most_purchased_item DESC

-- 5. Which item was the most popular for each customer?
with most_popular as (
	select s.customer_id, m.product_name, COUNT(s.product_id) AS order_count,
		dense_rank() over(
			partition by s.customer_id 
			order by count(s.product_id) desc
		) as rank
	from sales s
	join menu m on s.product_id = m.product_id
	group by s.customer_id, m.product_name
)

select customer_id, product_name, order_count
from most_popular
where rank = 1;

-- 6. Which item was purchased first by the customer after they became a member?
with first_purchased_when_became_member as(
	select sales.customer_id, menu.product_name, sales.order_date, members.join_date,
		dense_rank() over(
			partition by sales.customer_id
			order by sales.order_date
		) as rank
	from sales 
	join menu on sales.product_id = menu.product_id
	join members on sales.customer_id =  members.customer_id
	and sales.order_date > members.join_date
)

select customer_id, product_name, order_date, join_date
from first_purchased_when_became_member


-- 7. Which item was purchased just before the customer became a member?
with item_purchased_before_member as (
	select sales.customer_id, menu.product_name, sales.order_date, members.join_date,
		row_number() over(
			partition by sales.customer_id
			order by sales.order_date desc
		) as row_num
	from sales 
	join menu on sales.product_id = menu.product_id
	join members on sales.customer_id =  members.customer_id
	and sales.order_date < members.join_date
)

select customer_id, product_name, order_date, join_date
from item_purchased_before_member
where row_num = 1;


