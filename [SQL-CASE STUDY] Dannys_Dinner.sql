CREATE DATABASE dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');


  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  ------------------------------------------------------- 1.What is the total amount each customer spent at the restaurant? --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Select a.customer_id, Sum(price) as total
From (
    Select sales.*, menu.price
    From sales
    Join menu on sales.product_id = menu.product_id
    ) a
Group by a.customer_id;

  ------------------------------------------------------- 2.How many days has each customer visited the restaurant? --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Select customer_id, Count(order_date) as frequent
From sales
Group by customer_id;

  ------------------------------------------------------- 3.What was the first item from the menu purchased by each customer? --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  -- Cách 1:
With first_item as (
    Select customer_id, Min(order_date) as first_purchase_day
    From sales
    Group by customer_id
    )
Select a.*, b.product_id
From first_item a
Join sales b 
On a.first_purchase_day = b.order_date And a.customer_id = b.customer_id

  -- Cách 2:
With cte as(
    Select a.customer_id, a.order_date, b.product_name
        , DENSE_RANK() OVER(PARTITION BY a.customer_id ORDER BY a.order_date asc ) as Ranking
    From sales a
    Join menu b on a.product_id = b.product_id
    )
Select * From cte
Where Ranking = 1

  ------------------------------------------------------- 4.What is the most purchased item on the menu and how many times was it purchased by all customers? --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
With cte as (
    Select a.product_id, b.product_name, count(a.product_id) as order_count 
    From sales a
    Join menu b
    On a.product_id = b.product_id
    Group by a.product_id, b.product_name
    )
Select * from cte 
Where order_count = (Select max(order_count)
                     From cte
                    )

  ------------------------------------------------------- 5.Which item was the most popular for each customer? --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
With cte as (
    Select a.customer_id, b.product_name, COUNT(a.customer_id) As frequent
    From sales a
    Join menu b On a.product_id = b.product_id
    Group by a.customer_id, b.product_name
    )
, cte1 as (
    Select customer_id, max(frequent) as max
    From cte
    Group by customer_id
    )
Select cte.*
from cte
Join cte1 On cte.customer_id = cte1.customer_id And cte.frequent = cte1.[max];

  ------------------------------------------------------- 6.Which item was purchased first by the customer after they became a member? --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
With cte as (
    Select sales.*, join_date
    From sales
    Join members on sales.customer_id = members.customer_id
    Where order_date > join_date
    )
, cte1 as (
    Select customer_id, min(order_date) as first_member_order
    From cte
    Group by customer_id
    )
, cte2 as (
    Select cte1.*, cte.product_id
    From cte
    Join cte1
    On cte.customer_id = cte1.customer_id And cte.Order_Date = cte1.first_member_order
    )
Select cte2.*, menu.product_name
From cte2
Join menu
On cte2.product_id = menu.product_id

  ------------------------------------------------------- 7.Which item was purchased just before the customer became a member? --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
With cte as (
    Select sales.*, join_date
    From sales
    Join members on sales.customer_id = members.customer_id
    Where order_date < join_date
    )
, cte1 as (
    Select customer_id, max(order_date) as last_order_before_member
    From cte
    Group by customer_id
    )
, cte2 as (
    Select cte1.*, cte.product_id
    From cte
    Join cte1
    On cte.customer_id = cte1.customer_id And cte.Order_Date = cte1.last_order_before_member
    )
Select cte2.*, menu.product_name
From cte2
Join menu
On cte2.product_id = menu.product_id

  ------------------------------------------------------- 8.What is the total items and amount spent for each member before they became a member? --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
With cte as (
    Select sales.*, menu.price, members.join_date
    From sales
    Join menu
    On sales.product_id = menu.product_id
    Join members
    On sales.customer_id = members.customer_id
    Where order_date < join_date
    )
Select cte.customer_id, Sum(price) as spent
From cte
Group by cte.customer_id

  ------------------------------------------------------- 9.If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have? --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Select a.customer_id, Sum(D_point) as D_point
From (
    Select sales.*, menu.price, 
    Case
        When menu.product_name = 'sushi' Then menu.price * 20
        Else menu.price * 10
        End as D_point
    From sales
    Join menu on sales.product_id = menu.product_id
    ) a
Group by a.customer_id;

  ------------------------------------------------------- 10.In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January? --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
With cte_OfferValidity AS 
(
    Select 
        s.customer_id, 
        m.join_date, 
        s.order_date,
        DateAdd(Day, 6, m.join_date) as firstweek_ends, -- Thêm 6 ngày vào ngày tham gia
        menu.product_name, 
        menu.price
    From 
        sales s
    Left Join 
        members m On s.customer_id = m.customer_id
    Left Join 
        menu On s.product_id = menu.product_id
)
Select 
    customer_id,
    Sum(Case
            When order_date Between join_date And firstweek_ends Then 20 * price 
            When (order_date Not Between join_date And firstweek_ends) And product_name = 'sushi' Then 20 * price
            Else 10 * price
        End) As points
From 
    cte_OfferValidity
Where 
    order_date < '2021-02-01' -- Lọc điểm tháng 1
Group By 
    customer_id;

  ------------------------------------------------------- Bonus Task: Join all things --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Select s.customer_id, order_date, menu.product_name, menu.price, 
Case
    When s.order_date >= '2021-01-07' And m.join_date IS NOT NULL THEN 'Y' 
    When s.order_date >= '2021-01-09' And m.join_date IS NOT NULL THEN 'Y'
    Else 'N'
End as member
From sales s
Left Join menu 
    On s.product_id = menu.product_id
Left Join members m
    On s.customer_id = m.customer_id;






