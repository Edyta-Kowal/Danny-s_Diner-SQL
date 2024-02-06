/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
-- Bonus Questions


-- 1. What is the total amount each customer spent at the restaurant

select 	s.customer_id
		, sum(m.price)
from sales as s
	join menu as m 
		on s.product_id = m.product_id
group by 1;


-- 2. How many days has each customer visited the restaurant?

select  customer_id
		, count( distinct order_date) as visists
from sales
group by 1;


-- 3. What was the first item from the menu purchased by each customer?

with cte as (
	select 	s.customer_id
			, m.product_name
			, s.order_date
			, dense_rank() over (
			partition by s.customer_id
			order by s.order_date) as ranking
	from sales as s
		join menu as m 
			on s.product_id = m.product_id
	group by 1, 2, 3
			)

select	customer_id
		, product_name
from cte
where ranking = 1;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

with cte as (
	select m.product_name
			, count(s.product_id) as purchased
	from sales as s
		join menu as m
			on s.product_id = m.product_id
	group by 1
			)

select 	product_name
		, purchased
from cte
order by purchased desc
limit 1;


-- 5. Which item was the most popular for each customer?

with cte as (
	select 	s.customer_id
			, m.product_name
			, count(s.product_id) as purchased
			, dense_rank () over (
			partition by s.customer_id
			order by count(s.product_id) desc) as ranking
	from sales as s
		join menu as m
			on s.product_id = m.product_id
	group by 1, 2
			)

select 	customer_id
		, product_name
		, purchased
from cte
where ranking = 1;


-- 6. Which item was purchased first by the customer after they became a member?

with cte as (
	select 	s.customer_id
			, m.product_name 
			, s.order_date
			, dense_rank () over (
			partition by s.customer_id
			order by s.order_date) as ranking
	from sales as s
		join menu as m
			on s.product_id = m.product_id
		join members as mem
			on s.customer_id = mem.customer_id
	where s.order_date > mem.join_date
			)
			
select 	customer_id
		, product_name 
from cte
where ranking = 1;


-- 7. Which item was purchased just before the customer became a member?

with cte as (
	select 	s.customer_id
			, m.product_name 
			, s.order_date
			, dense_rank () over (
			partition by s.customer_id
			order by s.order_date desc) as ranking
	from sales as s
		join menu as m
			on s.product_id = m.product_id
		join members as mem
			on s.customer_id = mem.customer_id
	where s.order_date < mem.join_date
			)
			
select 	customer_id
		, product_name 
from cte
where ranking = 1;


-- 8. What is the total items and amount spent for each member before they became a member?

select 	s.customer_id
		, count(s.product_id) as items
		, sum(m.price) as amount
from sales as s
	join menu as m
		on s.product_id = m.product_id
	join members as mem
		on s.customer_id = mem.customer_id
where s.order_date < mem.join_date
group by 1
order by 1;


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

select 	s.customer_id
		, sum(case when product_name = 'sushi'
			  then m.price *20
			  else m.price *10
			  end) as points
from sales as s
	join menu as m
		on s.product_id = m.product_id
group by 1
order by 1; 


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
-- --  not just sushi - how many points do customer A and B have at the end of January?

select 	s.customer_id
		, sum(
			case 
				when product_name = 'sushi' then m.price *20
			 	when s.order_date between mem.join_date and (mem.join_date + interval '6 days') then m.price *20
			  	else m.price *10
			end) as points
from sales as s
	join menu as m
		on s.product_id = m.product_id
	join members as mem
		on s.customer_id = mem.customer_id
group by 1; 


/* --------------------
	Bonus Questions 
   --------------------*/	
   
-- Create the table with customer_id, order_date, product_name, price, member flag so Danny 
-- -- and his team can use to quickly derive insights without needing to join the underlying tables using SQL.

create view order_info as 
select 	s.customer_id
		, s.order_date	
		, m.product_name	
		, m.price	
		, case 
			when mem.join_date is null then 'N'
			when s.order_date < mem.join_date then 'N'
			else 'Y'
				end as member
from sales as s
		join menu as m
			on s.product_id = m.product_id
		left join members as mem
			on s.customer_id = mem.customer_id;


-- Danny also requires further information about the ranking of customer products, 
-- -- but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records
-- -- when customers are not yet part of the loyalty program.

select *
		, (case
			when member = 'N' then null
				else 
				rank () over (
				partition by customer_id, member
				order by order_date)
			end) as ranking
from order_info;

	