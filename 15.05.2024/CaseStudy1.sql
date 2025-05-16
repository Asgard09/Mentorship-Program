-- 1. What is the total amount each customer spent at the restaurant?
select s.[customer_id], SUM(m.[price]) as totalAmount
from [dbo].[sales] as s
join [dbo].[menu] as m on s.[product_id] = m.[product_id]
group by s.[customer_id];

-- 2. How many days has each customer visited the restaurant?
select [customer_id], COUNT(DISTINCT([order_date])) as visisted_date
from [dbo].[sales]
group by [customer_id];

