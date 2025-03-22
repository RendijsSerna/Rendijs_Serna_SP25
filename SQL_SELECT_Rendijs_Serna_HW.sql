--All animation movies released between 2017 and 2019 with rate more than 1, alphabetical
with animated_movies as (
SELECT f.film_id, f.title, f.release_year, f.rental_rate
FROM film f 
LEFT JOIN film_category fc ON f.film_id = fc.film_id
LEFT JOIN category c ON fc.category_id = c.category_id 
WHERE c.name = 'Animation'
AND f.release_year >= 2017 
AND f.release_year <= 2019
AND f.rental_rate > 1
ORDER BY f.title ASC
)
select  film_id,
		title,
		release_year,
		rental_rate
from animated_movies ;

--The revenue earned by each rental store after March 2017 (columns: address and address2 – as one column, revenue)
WITH rental_stores AS (
SELECT SUM(p.amount) AS revenue,
concat(a.address, ' ', a.address2 ) as adress
FROM rental r 
LEFT JOIN payment p ON r.rental_id = p.rental_id
LEFT JOIN inventory i ON r.inventory_id = i.inventory_id 
LEFT JOIN store s on s.store_id = i.store_id 
LEFT JOIN address a on s.address_id = a.address_id
WHERE p.payment_date > '2017-03-01'
GROUP BY a.address, a.address2
)
SELECT  revenue,
		adress
FROM rental_stores;

--Top-5 actors by number of movies (released after 2015) they took part in (columns: first_name, last_name, number_of_movies, sorted by number_of_movies in descending order)
WITH Actor_movies AS (
SELECT a.first_name, a.last_name, COUNT(fa.film_id) AS film_count
FROM actor a
LEFT JOIN film_actor fa ON a.actor_id = fa.actor_id
GROUP BY a.first_name, a.last_name
) 
SELECT  first_name,
		last_name,
		film_count
FROM Actor_movies
ORDER BY film_count desc
LIMIT 5;

--Number of Drama, Travel, Documentary per year (columns: release_year, number_of_drama_movies, number_of_travel_movies, number_of_documentary_movies), sorted by release year in descending order. Dealing with NULL values is encouraged)
WITH year_movie_genre_amounts AS (
SELECT  f.release_year, 
    COUNT(CASE WHEN c.name = 'Drama' THEN 1 END) AS number_of_drama_movies, 
    COUNT(CASE WHEN c.name = 'Travel' THEN 1 END) AS number_of_travel_movies,
    COUNT(CASE WHEN c.name = 'Documentary' THEN 1 END) AS number_of_documentary_movies
FROM  category c 
LEFT JOIN film_category fc ON fc.category_id = c.category_id
LEFT JOIN film f ON f.film_id = fc.film_id
GROUP BY f.release_year
)
SELECT  release_year,
		number_of_drama_movies,
		number_of_travel_movies,
		number_of_documentary_movies 
FROM year_movie_genre_amounts 
ORDER BY release_year DESC;


--Which three employees generated the most revenue in 2017? They should be awarded a bonus for their outstanding performance. 
with employee_amoint_store as (
SELECT s.first_name, s.last_name, 
       sum(p.amount) AS amount,
       s.store_id
FROM staff s
LEFT JOIN payment p ON s.staff_id = p.staff_id
LEFT JOIN store st ON st.store_id = s.store_id
WHERE EXTRACT(YEAR FROM p.payment_date) = 2017
GROUP BY s.first_name, s.last_name, s.store_id
)
select  first_name,
		last_name,
		amount,
		store_id
from employee_amoint_store
ORDER BY amount DESC 
limit 3;

--Which 5 movies were rented more than others (number of rentals), and what's the expected age of the audience for these movies? To determine expected age please use 'Motion Picture Association film rating system
WITH movie_rentals_ages AS (
SELECT f.title,
       COUNT(r.rental_id) AS number_of_rentals,
       CASE
           WHEN f.rating = 'G' THEN 'no limits'
           WHEN f.rating = 'PG' THEN 'no limits'
           WHEN f.rating = 'PG-13' THEN '13+'
           WHEN f.rating = 'R' THEN '17+'
           WHEN f.rating = 'NC-17' THEN '18+'
           ELSE 'Unknown' -- Default value for unknown ratings
       END AS age
FROM film f
LEFT JOIN inventory i ON f.film_id = i.film_id
LEFT JOIN rental r ON i.inventory_id = r.inventory_id
GROUP BY f.title, f.rating
)
SELECT  title,
		number_of_rentals,
		age
FROM movie_rentals_ages
ORDER BY number_of_rentals DESC
LIMIT 5;

--Which actors/actresses didn't act for a longer period of time than the others? V2
WITH actor_film_dates AS (
    SELECT 
        a.actor_id,
        a.first_name,
        a.last_name,
        MIN(f.release_year) AS first_film_year,
        MAX(f.release_year) AS last_film_year,
        (MAX(f.release_year) - MIN(f.release_year)) AS gap_years
    FROM actor a
    JOIN film_actor fa ON a.actor_id = fa.actor_id
    JOIN film f ON fa.film_id = f.film_id
    GROUP BY a.actor_id, a.first_name, a.last_name
)
SELECT 
    first_name,
    last_name,
    first_film_year,
    last_film_year,
    gap_years
FROM actor_film_dates
ORDER BY gap_years desc;
