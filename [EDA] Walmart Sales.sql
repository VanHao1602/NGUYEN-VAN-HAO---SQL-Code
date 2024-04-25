-------------------------------------------- Create database -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Create Database WalmartSales

Select  top 10 *
from dbo.[WalmartSalesData.csv]

-- I. **Feature Engineering:** 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 1. Tạo cột mới `time_of_day` nhằm đưa ra insight of sales vào Morning, Afternoon and Evening. 
-- This will help answer the question on which part of the day most sales are made.

Select a.Time, 
(Case 
     When a.Time Between '00:00:00' And '12:00:00' Then 'Morning'
     When a.Time Between '12:01:00' And '17:00:00' Then 'Afternoon'
     Else 'Evening'
End) as Time_of_day
From dbo.[WalmartSalesData.csv] a

-- Thêm cột Time_of_day --
Alter Table dbo.[WalmartSalesData.csv]
Add Time_of_day Nvarchar(20)
-- Fill giá trị vào cột Time_of_day --
Update dbo.[WalmartSalesData.csv]
        Set Time_of_day = (Case 
            When Time Between '00:00:00' And '12:00:00' Then 'Morning'
            When Time Between '12:01:00' And '17:00:00' Then 'Afternoon'
            Else 'Evening'
        End) 
        From dbo.[WalmartSalesData.csv]
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 2. Thêm cột `Day_of_Week` chứa thông tin ngày trong tuần mà giao dịch được thực hiện (Mon, Tue, Wed, Thur, Fri). 
-- This will help answer the question on which week of the day each branch is busiest.

Select a.Date, DATENAME(WEEKDAY, a.Date) AS Day_of_Week
from dbo.[WalmartSalesData.csv] a

-- Thêm cột Day_of_Week --
Alter Table dbo.[WalmartSalesData.csv]
Add Day_of_Week Nvarchar(20)

-- Fill giá trị vào cột Day_of_Week --
Update dbo.[WalmartSalesData.csv]
Set Day_of_Week = DATENAME(WEEKDAY, a.Date)
                  from dbo.[WalmartSalesData.csv] a
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 3. Thêm cột`month_name` chứa thông tin tháng mà giao dịch được thực hiện (Jan, Feb, Mar). 
-- Help determine which month of the year has the most sales and profit.

SELECT a.Date, DATENAME(MONTH, a.Date) AS Month_Name
from dbo.[WalmartSalesData.csv] a

-- Thêm cột Month_Name --
Alter Table dbo.[WalmartSalesData.csv]
Add Month_Name Nvarchar(20)

-- Fill giá trị vào cột Month_Name --
Update dbo.[WalmartSalesData.csv]
Set Month_Name = DATENAME(MONTH, a.Date)
                 from dbo.[WalmartSalesData.csv] a
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 4. Điều chỉnh cột Tax_5 --
Select (cogs * 0.05) as Tax
From dbo.[WalmartSalesData.csv]

Alter Table dbo.[WalmartSalesData.csv]
Add Tax FLOAT

Update dbo.[WalmartSalesData.csv]
Set Tax = (cogs * 0.05) 
            From dbo.[WalmartSalesData.csv]

Alter Table dbo.[WalmartSalesData.csv]
Drop Column Tax_5
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 5. Điều chỉnh cột Gross_margin_percentage đang bị sai định dạng dữ liệu --
Select (gross_income / Total) * 100 as Gross_margin_percentage
From dbo.[WalmartSalesData.csv]

Alter Table dbo.[WalmartSalesData.csv]
Add Gross_Margin_Pct FLOAT

Update dbo.[WalmartSalesData.csv]
Set Gross_Margin_Pct = (gross_income / Total) * 100 
                              From dbo.[WalmartSalesData.csv]

Alter Table dbo.[WalmartSalesData.csv]
Drop column gross_margin_percentage

-- II. **Exploratory Data Analysis (EDA):** 
---------------------------------------------------------------------- General -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Bộ data có bao nhiêu thành phố --
Select Distinct City
from dbo.[WalmartSalesData.csv]

-- Mỗi chi nhánh ở thành phố nào --
Select Distinct Branch, City
from dbo.[WalmartSalesData.csv]

------------------------------------------------------------ Business Questions To Answer -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------- Product --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------- 1. Có bao nhiêu product lines trong bộ data? --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Select Distinct Product_line
from dbo.[WalmartSalesData.csv]

---------------------------------------------------- 2. Payment method phổ biến nhất? --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Select Payment, Count(Payment) as Payment_Count
from dbo.[WalmartSalesData.csv]
Group by Payment
Order by Payment_Count DESC

---------------------------------------------------- 3. Product line nào bán chạy nhất? --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Select Product_Line, Count(Product_Line) as Selling
from dbo.[WalmartSalesData.csv]
Group by Product_Line
Order by Selling DESC

---------------------------------------------------- 4. Tổng doanh thu theo tháng? ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Select Month_Name, Sum(Total) as Revenue
from dbo.[WalmartSalesData.csv]
Group by Month_Name
Order by Revenue DESC

---------------------------------------------------- 5. Tháng có COGS lớn nhất? ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
with cte as(
    Select Month_Name, Sum(cogs) as Cog_by_Month
    from dbo.[WalmartSalesData.csv]
    Group by Month_Name
    )
, cte1 as(
Select Max(Cog_by_Month) as Max_Cog
From cte
)
Select cte.Month_Name, cte1.Max_Cog
From cte
Join cte1
On cte1.Max_Cog = cte.Cog_by_Month

---------------------------------------------------- 6. product line có doanh thu lớn nhất? ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
with cte as(
    Select Product_Line, Sum(Total) as Revenue_by_ProductLine
    from dbo.[WalmartSalesData.csv]
    Group by Product_Line
    )
, cte1 as(
Select Max(Revenue_by_ProductLine) as Max_Revenue
From cte
)
Select cte.Product_Line, cte1.Max_Revenue
From cte
Join cte1
On cte1.Max_Revenue = cte.Revenue_by_ProductLine

---------------------------------------------------- 7. Thành phố đem lại doanh thu cao nhất? ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
with cte as(
    Select City, Sum(Total) as Revenue_by_City
    from dbo.[WalmartSalesData.csv]
    Group by City
    )
, cte1 as(
Select Max(Revenue_by_City) as Max_Revenue
From cte
)
Select cte.City, cte1.Max_Revenue
From cte
Join cte1
On cte1.Max_Revenue = cte.Revenue_by_City

---------------------------------------------------- 8. Tổng thuế VAt chịu theo Product Line? ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
with cte as(
    Select Product_Line, Sum(Tax) as Tax_by_ProductLine
    from dbo.[WalmartSalesData.csv]
    Group by Product_Line
    )
, cte1 as(
Select Max(Tax_by_ProductLine) as Max_Tax
From cte
)
Select cte.Product_Line, cte1.Max_Tax
From cte
Join cte1
On cte1.Max_Tax = cte.Tax_by_ProductLine

---------------------------------------------------- 9. Đánh giá mỗi product line với "Good", "Bad". Good nếu lớn hơn average sales ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Tìm giá trị trung bình --
Select Avg(Total) as Avg_Sales
from dbo.[WalmartSalesData.csv] --> KQ trả ra 887066,365
-- Lập công thức truy vấn -- 
Select Product_Line, Sum(Total) as Sales_by_ProductLine,
(CASE
    When Sum(Total) > 887066.365 Then 'Good'
    Else 'Bad'
    End
) as Product_Line_Evaluation
From dbo.[WalmartSalesData.csv]
Group by Product_Line;

---------------------------------------------------- 10. Chi nhánh bán nhiều hơn average product sold? ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
With cte as (
    Select Branch, Sum(Quantity) as Qty_Branch
    From dbo.[WalmartSalesData.csv]
    Group by Branch) 
Select *
from cte
Where Qty_Branch > (Select Avg(Qty_Branch)
                        From cte)

---------------------------------------------------- 11. Product Line phổ biến nhất mỗi Gender? ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
With cte as (
Select Product_Line, Gender, Count(Gender) as ProductLine_by_Gender
From dbo.[WalmartSalesData.csv]
Group by Product_Line, Gender
)
,cte1 as (Select max(ProductLine_by_Gender) as Max_Qty_Male
from cte
Where Gender ='Male')
,cte2 as (Select max(ProductLine_by_Gender) as Max_Qty_Male
from cte
Where Gender ='Female')
Select *
From cte1, cte2

---------------------------------------------------- 12. Average rating của mỗi product line? ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Select Product_Line, Avg(Rating) as Avg_Rating
From dbo.[WalmartSalesData.csv]
Group by Product_Line
Order by Avg_Rating Desc

--------------------------------------------------------------------- Sales --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------- 1. Số lượng hoá đơn mỗi thời điểm trong ngày ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Select a.Time, Count(Invoice_ID) as Sales
From dbo.[WalmartSalesData.csv] a
Group by a.Time
Order by Sales Desc

---------------------------------------------------- 2. Nhóm khách hàng nào đem lại lợi nhuận nhất? ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Select a.Customer_type, Sum(Total) as Revenue
From dbo.[WalmartSalesData.csv] a
Group by a.Customer_type
Order by Revenue Desc

---------------------------------------------------- 3. Nhóm Khách Hàng nào phải chịu nhiều VAT nhất? ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Select a.Customer_type, Sum(Tax) as Tax
From dbo.[WalmartSalesData.csv] a
Group by a.Customer_type
Order by Tax Desc

--------------------------------------------------------------------- Customer --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------- 1. Có bao nhiêu nhóm Khách Hàng? ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Select Distinct Customer_type
From dbo.[WalmartSalesData.csv]

---------------------------------------------------- 2. Có bao nhiêu hình thức thanh toán? ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Select Distinct Payment
From dbo.[WalmartSalesData.csv]

---------------------------------------------------- 3. Loại Khách Hàng phổ biến nhất? ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Select Customer_type, Count(Invoice_ID) as Qty
From dbo.[WalmartSalesData.csv]
Group by Customer_type

---------------------------------------------------- 4. Nhóm Khách hàng nào mua nhiều nhất? ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Select Customer_type, Count(Invoice_ID) as Sales
From dbo.[WalmartSalesData.csv]
Group by Customer_type

---------------------------------------------------- 5. Giới tính phổ biến của Khách Hàng? ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Select Gender, Count(Invoice_ID) as Qty
from dbo.[WalmartSalesData.csv]
Group by Gender

---------------------------------------------------- 6. Phân bổ giới tính của Khách Hàng mỗi Branch? ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Select Branch, Gender, COUNT(Invoice_ID) as Qty_per_Branch_Gender
From dbo.[WalmartSalesData.csv]
Group by Branch, Gender;

---------------------------------------------------- 7. Thời gian nào trong ngày đạt Rating cao nhất? ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Select Time_of_day, Avg(Rating) as Avg_Rating
From dbo.[WalmartSalesData.csv]
Group by Time_of_day
Order by Avg_Rating

---------------------------------------------------- 8. Thời điểm nào trong ngày Khách Hàng rating cao nhất mỗi chi nhánh? ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Select Time_of_day, Branch, Avg(Rating) as Avg_Rating
From dbo.[WalmartSalesData.csv]
Group by Time_of_day, Branch
Order by Avg_Rating

---------------------------------------------------- 9. Ngày nào trong tuần ghi nhật Average Rating cao nhất? ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Select Day_of_week, Avg(Rating) as Avg_Rating
From dbo.[WalmartSalesData.csv]
Group by Day_of_week
Order by Avg_Rating

---------------------------------------------------- 10. Ngày nào trong tuần ghi nhận Rating cao nhất mỗi chi nhánh? ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Select Day_of_week, Branch, Avg(Rating) as Avg_Rating
From dbo.[WalmartSalesData.csv]
Group by Day_of_week, Branch
Order by Avg_Rating