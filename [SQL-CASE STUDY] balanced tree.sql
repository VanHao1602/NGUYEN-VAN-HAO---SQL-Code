CREATE TABLE product_hierarchy (
  "id" INTEGER,
  "parent_id" INTEGER,
  "level_text" VARCHAR(19),
  "level_name" VARCHAR(8)
);

CREATE TABLE product_prices (
  "id" INTEGER,
  "product_id" VARCHAR(6),
  "price" INTEGER
);

CREATE TABLE product_details (
  "product_id" VARCHAR(6),
  "price" INTEGER,
  "product_name" VARCHAR(32),
  "category_id" INTEGER,
  "segment_id" INTEGER,
  "style_id" INTEGER,
  "category_name" VARCHAR(6),
  "segment_name" VARCHAR(6),
  "style_name" VARCHAR(19)
);

CREATE TABLE sales (
  "prod_id" VARCHAR(6),
  "qty" INTEGER,
  "price" INTEGER,
  "discount" INTEGER,
  "member" VARCHAR(10),
  "txn_id" VARCHAR(6),
  "start_txn_time" TIMESTAMP
);

-------------------------------------------------------------- Case Study Questions -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/* 
The following questions can be considered key business questions and metrics that the Balanced Tree team requires for their monthly reports.
Each question can be answered using a single query - but as you are writing the SQL to solve each individual problem, keep in mind how you would generate all of these metrics in a single SQL script which the Balanced Tree team can run each month.
*/

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------- A. High Level Sales Analysis -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------- 1.What was the total quantity sold for all products? -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Select product_name, Sum(qty) as total_qty
From dbo.sales a
Join dbo.product_details b
On a.prod_id = b.product_id
Group by product_name
---------------------------------------------------------- 2.What is the total generated revenue for all products before discounts? -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Select product_name, Sum(qty*a.price) as Revenue
From dbo.sales a
Join dbo.product_details b
On a.prod_id = b.product_id
Group by product_name
---------------------------------------------------------- 3.What was the total discount amount for all products? -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Select product_name, Sum(discount * a.price * qty)/100 as discount_amount
From dbo.sales a
Join dbo.product_details b
On a.prod_id = b.product_id
Group by product_name

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------- B. Transaction Analysis -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------- 1.How many unique transactions were there? -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Select Count(Distinct txn_id) as trans_num
From dbo.sales

---------------------------------------------------------- 2.What is the average unique products purchased in each transaction? -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Select Avg(a.prod__num) as avg_prod_num
From (
    Select txn_id ,Count(Distinct prod_id) as prod__num
    From dbo.sales
    Group by txn_id
    ) a
---------------------------------------------------------- 3.What are the 25th, 50th and 75th percentile values for the revenue per transaction? -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

With percentile_value_cte as (
    Select txn_id, Sum(price * qty) as revenue
    From dbo.sales
    Group by txn_id
    )
Select Top 1 
    Percentile_Cont(0.25) Within Group (Order By revenue) Over () As median_25th,
    Percentile_Cont(0.5) Within Group (Order By revenue) Over () As median_50th,
    Percentile_Cont(0.75) Within Group (Order By revenue) Over () As median_75th
From percentile_value_cte;

---------------------------------------------------------- 4.What is the average discount value per transaction? -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

With avg_discount_amount_cte as (
    Select txn_id, 
        Sum(qty * price * discount)/100 as discount_amount
    From dbo.sales
    Group by txn_id
    )
Select avg(discount_amount) as avg_discount_amount
From avg_discount_amount_cte;

---------------------------------------------------------- 5.What is the percentage split of all transactions for members vs non-members? -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
With trans_split_cte as (
    Select member, Count(txn_id) as trans_num
    From dbo.sales
    Group by member
    )
Select 
    trans_split_cte.*,
    Cast((100.0 * trans_num / (Select Sum(trans_num) From trans_split_cte)) As Float) As trans_pct
From trans_split_cte
Group by member, trans_num;

---------------------------------------------------------- 6.What is the average revenue for member transactions and non-member transactions? -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

With revn_split_cte as (
    Select txn_id, member, Sum(price * qty) as revenue
    From dbo.sales
    Group by txn_id, member
    )
Select 
    member,
    Avg(revenue) as avg_revenue
From revn_split_cte
Group by member;

-------------------------------------------------------------- C. Product Analysis -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------- 1.What are the top 3 products by total revenue before discount? -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Select Top 3 product_name, Sum(qty * a.price) as revenue_before_discount
From dbo.sales a
Join dbo.product_details b
On a.prod_id = b.product_id
Group by product_name

---------------------------------------------------------- 2.What is the total quantity, revenue and discount for each segment? -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Select segment_name,
        Sum(qty) as quantity,
        Sum(qty * a.price) as revenue,
        Sum(qty * a.price * discount)/100 as discount
From dbo.sales a
Join dbo.product_details b
On a.prod_id = b.product_id
Group by segment_name;

---------------------------------------------------------- 3.What is the top selling product for each segment? -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

With revenue_by_prod as (
    Select prod_id, Sum(qty * price) as revenue
    From dbo.sales
    Group by prod_id
)
, join_seg_name as (
    Select revenue_by_prod.*, segment_name
    From revenue_by_prod
    Join dbo.product_details a
    On a.product_id = revenue_by_prod.prod_id
    )
, max_by_seg_name as (
    Select segment_name, Max(revenue) as max_revenue
    From join_seg_name
    Group by segment_name
)
, last_join as (
    Select a.segment_name, prod_id, max_revenue
    From max_by_seg_name a
    Join join_seg_name b
    On a.max_revenue = b.revenue
)
Select a.segment_name, product_name, max_revenue
From last_join a
Join dbo.product_details b
On a.prod_id = b.product_id

---------------------------------------------------------- 4.What is the total quantity, revenue and discount for each category? -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Select category_name,
        Sum(qty) as quantity,
        Sum(qty * a.price) as revenue,
        Sum(qty * a.price * discount)/100 as discount
From dbo.sales a
Join dbo.product_details b
On a.prod_id = b.product_id
Group by category_name;

---------------------------------------------------------- 5.What is the top selling product for each category? -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

With revenue_by_prod as (
    Select prod_id, Sum(qty * price) as revenue
    From dbo.sales
    Group by prod_id
)
, join_cat_name as (
    Select revenue_by_prod.*, category_name
    From revenue_by_prod
    Join dbo.product_details a
    On a.product_id = revenue_by_prod.prod_id
    )
, max_by_cat_name as (
    Select category_name, Max(revenue) as max_revenue
    From join_cat_name
    Group by category_name
)
, last_join as (
    Select a.category_name, prod_id, max_revenue
    From max_by_cat_name a
    Join join_cat_name b
    On a.max_revenue = b.revenue
)
Select a.category_name, product_name, max_revenue
From last_join a
Join dbo.product_details b
On a.prod_id = b.product_id;

---------------------------------------------------------- 6.What is the percentage split of revenue by product for each segment? -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

With cte as (
Select prod_id, segment_name, prod_revenue
From (  Select prod_id, Sum(qty * price) as prod_revenue
        From dbo.sales
        Group by prod_id) b
Join dbo.product_details a
On b.prod_id = a.product_id
)
, cte1 as (
    Select segment_name, Sum(prod_revenue) as seg_revenue
    From cte
    Group by segment_name
)
Select cte.prod_id, cte.segment_name, prod_revenue, (prod_revenue *100)/seg_revenue as revenue_pct
From cte
Join cte1
On cte.segment_name = cte1.segment_name;

---------------------------------------------------------- 7.What is the percentage split of revenue by segment for each category? -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
With seg_revenue_cte as (
    Select segment_name, Sum( qty * price) as seg_revenue
    From (
        Select a.*, segment_name
        From dbo.sales a
        Join dbo.product_details b
        On a.prod_id = b.product_id
        ) a
    Group by segment_name
    )
, join_category_cte as (
    Select a.segment_name, category_name, seg_revenue
    From seg_revenue_cte a
    Join dbo.product_details b
    On b.segment_name = a.segment_name
)
, cat_revenue_cte as (
    Select a.category_name, Sum(Distinct seg_revenue) as cat_revenue 
    From join_category_cte a
    Group by a.category_name
    )
, revenue_pct_cte as (
    Select segment_name, a.category_name, seg_revenue, cat_revenue
    From join_category_cte a
    Join cat_revenue_cte b
    On a.category_name = b.category_name
)
Select Distinct segment_name, category_name, seg_revenue, 
        (100 * seg_revenue / cat_revenue) as revenue_pct
From revenue_pct_cte;

---------------------------------------------------------- 8.What is the percentage split of total revenue by category? -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

With cat_revenue_cte as (
    Select category_name, Sum(a.price * qty) as revenue
    From dbo.sales a
    Join dbo.product_details b
    On a.prod_id = b.product_id
    Group by category_name
)
Select cat_revenue_cte.*, (100 * revenue)/ (Select Sum(revenue) 
                                        From  cat_revenue_cte) as revenue_pct
From cat_revenue_cte;

---------------------------------------------------------- 9.What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions) -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

With prod_count as (
    Select product_name, Count(prod_id) prod_count
    From dbo.sales a
    Join dbo.product_details b
    On a.prod_id = b.product_id
    Group by product_name
)
, penetration_pct as(
    Select product_name, (100 * prod_count) / (
                                                Select Count(Distinct txn_id) as trans_num
                                                From dbo.sales) as penetration
    From prod_count
    )
Select * From penetration_pct

---------------------------------------------------------- Bonus Challenge -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/* Use a single SQL query to transform the product_hierarchy and product_prices datasets to the product_details table.

Hint: you may want to consider using a recursive CTE to solve this problem!

I did not use recursive CTEs or nested queries here, just consequent self joins on parent_id and id columns. The product_name column is generated by the concat() function. */
