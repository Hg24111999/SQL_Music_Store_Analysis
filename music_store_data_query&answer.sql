use music_databse;
-- Q1. who is the senior most employee based on job title?
select concat(first_name,last_name) from music_databse.employee order by levels desc limit 1;

-- Q2 which countries have the most invoices?
select billing_country,count(invoice_id) as count1 from  music_databse.invoice group by billing_country order by count1 desc limit 1 ;

-- Q3 What are top 3 values of total invoice?
select total from music_databse.invoice order by total desc limit 3;

-- Q4 which city has the best customers ? we would like to throw a promotional music festival in the city we made the most money.Write a query that returns one 
-- city that has the highest sum of invoice totals. Return both the city name & sum of all invoice totals.

select billing_city,sum(total) from music_databse.invoice group by billing_city order by sum(total) desc limit 1;

-- Q5 Who is the best customer? The customer who has spent the most money will be declared the best customer. write a query that return the person who has spent the most money

select first_name,last_name,customer_id from 
music_databse.customer where customer_id=
(select customer_id from music_databse.invoice group by customer_id order by sum(total) desc limit 1);

-- OR METHOD 2

SELECT customer.customer_id,customer.first_name,customer.last_name,SUM(invoice.total) as total
from customer
join invoice on customer.customer_id=invoice.customer_id
group by customer.customer_id
order by total
desc limit 1;

-- Q6 Write query to return the email,first name,last name & genre of all Rock Music listeners.
-- Return your list ordered alphabetically by email starting with A

select Distinct customer.email,customer.first_name,customer.last_name
from customer 
join invoice on customer.customer_id=invoice.customer_id
join invoice_line on invoice.invoice_id=invoice_line.invoice_id
where invoice_line.track_id in (
select track_id from track
join genre on genre.genre_id=track.genre_id
where genre.name='Rock'
)order by email;

-- or method 2

select distinct customer.email,customer.first_name,customer.last_name
from customer
join invoice on customer.customer_id=invoice.customer_id
join invoice_line on invoice.invoice_id=invoice_line.invoice_id
join track on track.track_id=invoice_line.track_id
join genre on genre.genre_id=track.genre_id
where genre.name LIKE 'Rock'
order by email;

-- Q7 Let's invite the artist who have written the most rock music in our dataset.write a query that returns the artist name and total track count of the top 10 rock bands.
select artist.name,count(*) from artist
join album on album.artist_id=artist.artist_id
join track on track.album_id=album.album_id
where track_id in (
select track_id from track
join genre on genre.genre_id=track.genre_id
where genre.name='Rock')
group by artist.artist_id
order by count(*) desc;

-- method 2 

select artist.artist_id,artist.name,count(artist.artist_id) as number_of_songs
from track
join album on track.album_id=album.album_id
join artist on  album.artist_id=artist.artist_id
join genre on genre.genre_id=track.genre_id
where genre.name LIKE 'ROCK'
group by artist.artist_id,artist.name
order by number_of_songs DESC
limit 10;

-- Q8 Return all the track names that have a song length longer than the average song length.Return the Name and Milliseconds for each track.
-- order by the song length with longest songs listed first.
select name,milliseconds from track 
where milliseconds>
(select avg(milliseconds) from track)
order by milliseconds desc;

-- Q9 Find how much amount spent by each customer on best selling artist? write a query to return customer name,artist name and total spent
With best_selling_artist as (select artist.artist_id,artist.name AS artist_name,invoice_line.track_id,sum(invoice_line.unit_price *invoice_line.quantity) as total
from artist
join album on album.artist_id=artist.artist_id
join track on track.album_id=album.album_id
join invoice_line on track.track_id=invoice_line.track_id
group by artist.artist_id
order by total desc
limit 1)
select c.customer_id,c.first_name,c.last_name,bsa.artist_name,
sum(il.unit_price*il.quantity) AS amount_spent
from invoice i
join customer c on i.customer_id=c.customer_id
join invoice_line il on il.invoice_id=i.invoice_id
join track t on t.track_id=il.track_id
join album alb on alb.album_id=t.album_id
join best_selling_artist bsa on bsa.artist_id=alb.artist_id
group by 1,2,3,4
order by 5 desc;

-- Important
-- Q10 We want to find out the most popular music Genre for each country.We determine the most popular genre as the genre with the highest amount of purchases.
-- Write a query that returns each country along with top Genre .For countries where the maximum number of purchases is shared return all genres

With popular_genre AS
(
select count(invoice_line.quantity) as purchases,customer.country,genre.name,genre.genre_id,
ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY count(invoice_line.quantity) DESC) AS Rowno
from
genre
join track on track.genre_id=genre.genre_id
join invoice_line on invoice_line.track_id=track.track_id
join invoice on invoice.invoice_id=invoice_line.invoice_line_id
join customer on customer.customer_id=invoice.customer_id
group by customer.country,genre.name,genre.genre_id
order by country ASC, purchases DESC
)
select * from popular_genre where RowNo <=1;

-- Q11.Write a query that determines the customer that has spent the most on music for each country.Write a query that returns the country along with the top customner 
-- and how much they spent. For countries where the top amount spent is shared,provide all customers who spent this amount.

With Recursive
spent_each_customer
As
(
select customer.customer_id,first_name,last_name,country,sum(total) as spent
from 
customer
join invoice on invoice.customer_id=customer.customer_id
group by customer.customer_id,first_name,last_name,country
order by country asc,spent desc),
max_spent_each_customer AS (
select max(spent) as spent,country
from spent_each_customer
group by country
)
select cc.country,cc.spent,cc.first_name,cc.last_name,cc.customer_id
from spent_each_customer AS cc
join max_spent_each_customer AS ms
on cc.country=ms.country
where cc.spent=ms.spent
order by country;

-- Method 2

With 
spent_each_customer
As
(
select customer.customer_id,first_name,last_name,billing_country,sum(total) as spent,
row_number () OVER (partition by billing_country order by sum(total) desc) AS Row_No
from 
customer
join invoice on invoice.customer_id=customer.customer_id
group by customer.customer_id,first_name,last_name,billing_country
order by billing_country asc,spent desc)
select * from spent_each_customer where Row_No<=1;
