/*	Question Set 1 - Easy */

/* Q1: Who is the senior most employee based on job title? */	
		SELECT 
			first_name,
			last_name,
			title,
			levels 
		FROM employee 
		ORDER by levels desc
		
/* Q2: Which countries have the most Invoices? */
		SELECT 
			COUNT(*) as C, 
			billing_country
		FROM invoice
		GROUP BY billing_country
		ORDER BY C desc

/* Q3: What are top 3 values of total invoice? */
		SELECT *
		FROM invoice
		ORDER BY total desc
		LIMIT 3

/* Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals */
		SELECT 
			billing_city,
			SUM(total) as Invoice_total
		FROM invoice 
		GROUP BY billing_city
		ORDER BY Invoice_total DESC

/* Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money.*/
		SELECT  
			customer.customer_id,
			customer.first_name,
			customer.last_name,
			SUM(invoice.total) as Invoice_total
		FROM customer 
		JOIN invoice
			ON customer.customer_id = invoice.customer_id
		GROUP BY customer.customer_id
		ORDER BY Invoice_total DESC
		LIMIT 1

/* Question Set 2 - Moderate */

/* Q6: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */
		SELECT 
			first_name,
			last_name,
			DISTINCT email 
		FROM customer
		JOIN invoice 
			ON customer.customer_id = invoice.customer_id
		JOIN invoice_line 
			ON invoice_line.invoice_id = invoice.invoice_id
		WHERE track_id IN (
					SELECT track_id 
					FROM genre
					JOIN track ON genre.genre_id = track.genre_id
					WHERE genre.name='Rock'		)
		ORDER BY email


/* Q7: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */
		SELECT 
			artist.name, 
			COUNT(artist.artist_id) as No_of_songs
		FROM track
		JOIN album 
			ON album.album_id = track.album_id
		JOIN artist 
			ON artist.artist_id = album.artist_id
		JOIN genre 
			ON genre.genre_id = track.genre_id
		WHERE genre.name='Rock'
		GROUP BY artist.artist_id
		ORDER BY No_of_songs DESC
		LIMIT 10

/* Q8: Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */
		SELECT 
			name,
			milliseconds 
		FROM track 
		WHERE milliseconds >(
						SELECT ROUND(AVG(milliseconds),2) as Average 
						FROM track 	)
		ORDER BY milliseconds DESC

/* Question Set 3 - Advance */

/* Q9: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent */

/* Steps to Solve: First, find which artist has earned the most according to the InvoiceLines. Now use this artist to find 
which customer spent the most on this artist. For this query, you will need to use the Invoice, InvoiceLine, Track, Customer, 
Album, and Artist tables. Note, this one is tricky because the Total spent in the Invoice table might not be on a single product, 
so you need to use the InvoiceLine table to find out how many of each product was purchased, and then multiply this by the price
for each artist. */
		--CT (Common Table Expression) for creating TEMPORARY TABLE

		WITH best_selling_artist AS (
		SELECT 
				artist.artist_id as artist_id ,
				artist.name as artist_name,
				SUM(invoice_line.unit_price * invoice_line.quantity) as Total_Sales
			FROM invoice_line 
			JOIN track 
				ON track.track_id = invoice_line.track_id
			JOIN album 
				ON album.album_id = track.album_id
			JOIN artist 
				ON artist.artist_id = album.artist_id	
			GROUP BY 1
			ORDER BY 3 DESC
			LIMIT 1
		)
		
		SELECT 
				C.first_name,
				C.last_name,
				bsa.artist_name,
				SUM(IL.unit_price * IL.quantity) as Amount_spent
			FROM invoice I
			JOIN customer C 
				ON C.customer_id = I.customer_id
			JOIN invoice_line IL 
				ON IL.invoice_id = I.invoice_id
			JOIN track T 
				ON T.track_id = IL.track_id
			JOIN album A
				ON A.album_id = T.album_id
			JOIN best_selling_artist bsa
				ON bsa.artist_id = A.artist_id
			GROUP BY 1,2,3
			ORDER BY 4 DESC

/* Q10: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */

/* Steps to Solve:  There are two parts in question- first most popular music genre and second need data at country level. */

/* Method 1: Using CTE */
		WITH popular_genre AS (
		SELECT 
			COUNT(IL.quantity) as highest_sales,
			C.country,
			G.name,
			G.genre_id,
			ROW_NUMBER() 
				OVER(
					PARTITION BY C.country
					ORDER BY COUNT(IL.quantity) DESC) AS RowNo
		FROM invoice_line IL
		JOIN invoice I
			ON I.invoice_id = IL.invoice_id
		JOIN customer C
			ON C.customer_id = I.customer_id
		JOIN track T
			ON T.track_id = IL.track_id
		JOIN genre G
			ON G.genre_id = T.genre_id
		GROUP BY 2,3,4
		ORDER BY 2 ASC, 1 DESC )
		
		SELECT * FROM popular_genre WHERE RowNo <= 1

/* Method 2: : Using Recursive */
		WITH RECURSIVE sales_per_country AS (
		SELECT 
			COUNT(*) as purchases_per_genre,
			C.country,
			G.name,
			G.genre_id
		FROM invoice_line IL
		JOIN invoice I
			ON I.invoice_id = IL.invoice_id
		JOIN customer C
			ON C.customer_id = I.customer_id
		JOIN track T
			ON T.track_id = IL.track_id
		JOIN genre G
			ON G.genre_id = T.genre_id
		GROUP BY 2,3,4
		ORDER BY 2 ),
		
		max_genre_per_country AS(
				SELECT 
					MAX(purchases_per_genre) as max_genre_number,
					C.country
				FROM sales_per_country
				GROUP BY 2
				ORDER BY 2	)
				
		SELECT sales_per_country,*
			FROM sales_per_country S
			JOIN max_genre_per_country M
				ON S.country = M.country
			WHERE S.highest_sales = M.max_genre_number

/* Q11: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

/* Steps to Solve:  Similar to the above question. There are two parts in question- 
first find the most spent on music for each country and second filter the data for respective customers. */

/* Method 1: using CTE */
		WITH RECURSIVE 	customer_with_country AS (
		SELECT 
				customer.customer_id,
				first_name,
				last_name,
				billing_country,	
				SUM(total) as Total_spending,
				ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC ) as RowNo
			FROM invoice
			JOIN customer 
				ON customer.customer_id = invoice.customer_id
			GROUP BY 1,2,3,4
			ORDER BY 4 ASC,5 DESC	)
			
		SELECT * FROM customer_with_country WHERE RowNo <= 1

/* Method 2: Using Recursive */
		WITH RECURSIVE 	customer_with_country AS (
		SELECT 
				customer.customer_id,
				first_name,
				last_name,
				billing_country,
				SUM(total) as Total_spending
			FROM invoice
			JOIN customer 
				ON customer.customer_id = invoice.customer_id
			GROUP BY 1,2,3,4
			ORDER BY 1,5 DESC	),
	
		country_max_spending AS (
		SELECT 
				billing_country,
				MAX(total_spending) as max_spending
			FROM customer_with_country
			GROUP BY billing_country	)

		SELECT
				cc.billing_country,
				cc.total_spending,
				cc.first_name,
				cc.last_name,
				cc.customer_id
			FROM customer_with_country cc
			JOIN country_max_spending ms
				ON cc.billing_country = ms.billing_country
			WHERE cc.total_spending = ms.max_spending
			ORDER BY 1








