Create Database MusicSales

---------------------------------- Q1: Who is the senior most employee based on job title? ------------------------------------------------------------------------------------------------------------

Select title, last_name, first_name, levels
From employee
Order by levels Desc; --> Mohan Madam

---------------------------------- Q2: Which countries have the most Invoices? --------------------------------------------------------------------------------------------------------------------

With cte as(
    Select count(invoice_id) as invoice_qty, billing_country
    From dbo.invoice
    Group by billing_country
    )
Select * 
From cte
Where cte.invoice_qty = (Select max(cte.invoice_qty) 
                         from cte);

---------------------------------- Q3: What are top 3 values of total invoice? --------------------------------------------------------------------------------------------------------------------

Select Top 3 invoice_id, total
            ,ROW_NUMBER() OVER(ORDER by total DESC) As Ranking
From dbo.invoice
Order By Ranking Asc;

---------------------------------- Q4: Which city has the best customers? -------------------------------------------------------------------------------------------------------------------------
/* We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals */

With cte as(
    Select Sum(total) as total, billing_city
    From dbo.invoice
    Group by billing_city
    )
Select * 
From cte
Where cte.total = (Select max(cte.total) 
                         from cte);

---------------------------------- Q5: Who is the best customer? ---------------------------------------------------------------------------------------------------------------------------------
-- The customer who has spent the most money will be declared the best customer --

With cte as(
    Select Sum(total) as total, customer_id
    From dbo.invoice
    Group by customer_id
    )
        ,cte1 as(
        Select * 
        From cte
        Where cte.total = (Select max(cte.total) 
                                from cte)
        )
        Select cte1.customer_id, first_name, last_name, phone, email
        From cte1
        Join dbo.customer b
        On cte1.customer_id = b.customer_id;

---------------------------------- Q6: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. Return your list ordered alphabetically by email starting with A ---------------------------------------------------------------------------

Select Distinct email, first_name, last_name
From dbo.customer a
    Join dbo.invoice b On a.customer_id = b.customer_id
    Join dbo.invoice_line c On b.invoice_id = c.invoice_id
Where track_id In(
	Select track_id 
    From track 
	Join genre On dbo.track.genre_id = dbo.genre.genre_id
	Where dbo.genre.[name] Like 'Rock'
)
Order by email;

---------------------------------- Q7: Let's invite the artists who have written the most rock music in our dataset. ---------------------------------------------------------------------------------------------------------------------------------
-- Write a query that returns the Artist name and total track count of the top 10 rock bands --

Select top 10 c.artist_id, c.name, Count(c.artist_id) as song_number
From dbo.track a
    Join dbo.album b On b.album_id = a.album_id
    Join dbo.artist c On c.artist_id = b.artist_id
    Join dbo.genre  d On d.genre_id = a.genre_id
Where d.name Like 'Rock'
Group by c.artist_id, c.name
Order by Count(c.artist_id) Desc;

---------------------------------- Q8: Return all the track names that have a song length longer than the average song length. ---------------------------------------------------------------------------------------------------------------------------------

Select a.name, a.milliseconds
From dbo.track a
Where a.milliseconds > (Select AVG(a.milliseconds) As avg_length
	                    From dbo.track a) --> Giá trị average = 359599 ms
Order by a.milliseconds Desc;

---------------------------------- Q9: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent ---------------------------------------------------------------------------------------------------------------------------------

With cte as (
	Select top 1 d.artist_id as artist_id, d.[name] as artist_name, SUM(a.unit_price * a.quantity) as total_sales
	From dbo.invoice_line a
	Join dbo.track b On b.track_id = a.track_id
	Join dbo.album c On c.album_id = b.album_id
	Join dbo.artist d On d.artist_id = c.artist_id
	Group by d.artist_id, d.name
	Order by total_sales Desc
    )
Select f.customer_id, f.first_name, f.last_name, cte.artist_name, SUM(a.unit_price * a.quantity) AS amount_spent
FROM invoice e
    Join customer f On f.customer_id = e.customer_id
    Join invoice_line a On a.invoice_id = e.invoice_id
    Join track h On h.track_id = a.track_id
    Join album i On i.album_id = h.album_id
    Join cte  On cte.artist_id = i.artist_id
GROUP BY f.customer_id, f.first_name, f.last_name, cte.artist_name
ORDER BY amount_spent

---------------------------------- Q9: The most popular music Genre for each country ---------------------------------------------------------------------------------------------------------------------------------

With cte as 
(
    Select top 1000 COUNT(a.quantity) as purchases, c.country, e.name, e.genre_id
                    ,ROW_NUMBER() OVER(PARTITION BY c.country ORDER BY COUNT(a.quantity) DESC) as Ranking 
    From invoice_line a
        Join invoice b On b.invoice_id = a.invoice_id
        Join customer c On c.customer_id = b.customer_id
        Join track d On d.track_id = a.track_id
        Join genre e On e.genre_id = d.genre_id
	Group by c.country, e.name, e.genre_id
	Order bY c.country Asc,  purchases Desc
)
Select * From cte 
Where Ranking = 1 

---------------------------------- Q10: Determines the customer that has spent the most on music for each country ---------------------------------------------------------------------------------------------------------------------------------

With cte as (
		Select top 1000 b.customer_id, first_name, last_name, billing_country, SUM(total) AS total_spending
	           ,ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS Ranking 
		From invoice a
		Join customer b On b.customer_id = a.customer_id
		Group by b.customer_id, first_name, last_name, billing_country
		Order by total_spending ASC, Ranking DESC)
Select * From cte 
Where Ranking = 1

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

