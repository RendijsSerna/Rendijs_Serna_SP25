-- Create a view called 'sales_revenue_by_category_qtr' that shows the film category and total sales revenue for the current quarter and year. The view should only display categories with at least one sale in the current quarter. 
CREATE OR REPLACE VIEW sales_revenue_by_category_qtr AS
SELECT
    c.name AS category,
    SUM(p.amount) AS total_sales_revenue
FROM
    payment p
    INNER JOIN rental r ON p.rental_id = r.rental_id
    INNER JOIN inventory i ON r.inventory_id = i.inventory_id
    INNER JOIN film f ON i.film_id = f.film_id
    INNER JOIN film_category fc ON f.film_id = fc.film_id
    INNER JOIN category c ON fc.category_id = c.category_id
WHERE
    DATE_PART('year', p.payment_date) = DATE_PART('year', CURRENT_DATE) -- test CASE DATE '2017-01-31'
    AND DATE_PART('quarter', p.payment_date) = DATE_PART('quarter', CURRENT_DATE)
GROUP BY
    c.name
HAVING
    SUM(p.amount) > 0
ORDER BY
    total_sales_revenue DESC;

-- get data for current quarter 
SELECT * FROM sales_revenue_by_category_qtr;

--Create a query language function called 'get_sales_revenue_by_category_qtr' that accepts one parameter representing the current quarter and year and returns the same result as the 'sales_revenue_by_category_qtr' view.
CREATE OR REPLACE FUNCTION get_sales_revenue_by_category_qtr(reference_date DATE DEFAULT CURRENT_DATE)
RETURNS TABLE (
    category TEXT,
    total_sales_revenue NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.name AS category,  
        SUM(p.amount) total_sales_revenue  
    FROM
        payment p
        INNER JOIN rental r ON p.rental_id = r.rental_id
        INNER JOIN inventory i ON r.inventory_id = i.inventory_id
        INNER JOIN film f ON i.film_id = f.film_id
        INNER JOIN film_category fc ON f.film_id = fc.film_id
        INNER JOIN category c ON fc.category_id = c.category_id
    WHERE
        DATE_PART('year', p.payment_date) = DATE_PART('year', reference_date) 
        AND DATE_PART('quarter', p.payment_date) = DATE_PART('quarter', reference_date)
    GROUP BY
        c.name
    HAVING
        SUM(p.amount) > 0
    ORDER BY
        total_sales_revenue DESC;
END;
$$ LANGUAGE plpgsql;

-- current quarter
SELECT * FROM  get_sales_revenue_by_category_qtr(); 

-- test case quarter 
SELECT * FROM get_sales_revenue_by_category_qtr('2017-01-31');

DROP FUNCTION most_popular_films_by_countries(text[])


-- Create a function that takes a country as an input parameter and returns the most popular film in that specific country. 
--The function should format the result set as follows:
CREATE OR REPLACE FUNCTION most_popular_films_by_countries(input_countries TEXT[])
RETURNS TABLE (
    country TEXT,
    film TEXT,
    rating TEXT,
    language TEXT,
    length INTEGER,
    release_year TEXT
) AS $$
BEGIN
    RETURN QUERY
    WITH country_rentals AS (
        SELECT
            co.country::TEXT,
            f.title::TEXT,
            f.rating::TEXT,
            l.name::TEXT AS language,
            f.length::INTEGER,
            f.release_year::TEXT,
            COUNT(r.rental_id) AS rental_count
        FROM
            country co
            INNER JOIN city ci ON co.country_id = ci.country_id
            INNER JOIN address a ON ci.city_id = a.city_id
            INNER JOIN customer cu ON a.address_id = cu.address_id
            INNER JOIN rental r ON cu.customer_id = r.customer_id
            INNER JOIN inventory i ON r.inventory_id = i.inventory_id
            INNER JOIN film f ON i.film_id = f.film_id
            INNER JOIN language l ON f.language_id = l.language_id
        WHERE
            co.country = ANY(input_countries)
        GROUP BY
            co.country, f.film_id, f.title, f.rating, l.name, f.length, f.release_year
    )
    SELECT DISTINCT ON (cr.country)
        cr.country,
        cr.title AS film,
        cr.rating,
        cr.language,
        cr.length,
        cr.release_year
    FROM
        country_rentals cr
    ORDER BY
        cr.country, cr.rental_count DESC;
END;
$$ LANGUAGE plpgsql;

-- test case
SELECT * FROM most_popular_films_by_countries(ARRAY['United States', 'Afghanistan', 'Brazil']);


--Create a function that generates a list of movies available in stock based on a partial title match (e.g., movies containing the word 'love' in their title). 
CREATE OR REPLACE FUNCTION films_in_stock_by_title(input_text TEXT)
RETURNS TABLE (
    row_num BIGINT,
    film_title TEXT,
    language TEXT,
    customer_name TEXT,
    rental_date DATE
) AS $$
BEGIN
    RETURN QUERY
    WITH distinct_results AS (
        SELECT DISTINCT ON (f.title)
            f.title::TEXT AS film_title,
            l.name::TEXT AS language,
            c.first_name || ' ' || c.last_name::TEXT AS customer_name,
            r.rental_date::DATE
        FROM
            film f
        INNER JOIN inventory i ON f.film_id = i.film_id
        INNER JOIN rental r ON i.inventory_id = r.inventory_id
        INNER JOIN customer c ON r.customer_id = c.customer_id
        INNER JOIN language l ON f.language_id = l.language_id
        WHERE
            f.title LIKE UPPER(input_text)
            AND r.return_date IS NOT NULL
    )
    SELECT
        row_number() OVER () AS row_num,
        dr.film_title,
        dr.language,
        dr.customer_name,
        dr.rental_date
    FROM distinct_results dr;

    IF NOT FOUND THEN
        RAISE NOTICE 'No movies found for title: ', input_text;
    END IF;
END;
$$ LANGUAGE plpgsql;


-- test case
SELECT * FROM films_in_stock_by_title('%love%');
-- fail test case for no movies
SELECT * FROM films_in_stock_by_title('%asdasdasdasdadas%');


-- Create a procedure language function called 'new_movie' that takes a movie title as a parameter and inserts a new movie with the given title in the film table. The function should generate a new unique film ID, set the rental rate to 4.99, the rental duration to three days, the replacement cost to 19.99. The release year and language are optional and by default should be current year and Klingon respectively. The function should also verify that the language exists in the 'language' table. Then, ensure that no such function has been created before; if so, replace it.
-- im very confused by this task
-- why do i need to generate a new id if film_id field is serial?
CREATE OR REPLACE FUNCTION new_movie(new_movie_title text)
RETURNS void AS $$
DECLARE
    release_year INTEGER;
    default_language_id INTEGER;
    movie_id INTEGER;
BEGIN
    release_year := EXTRACT(YEAR FROM CURRENT_DATE);
    default_language_id := (SELECT language_id FROM language WHERE name = ('Klingon'));
    movie_id := (SELECT film_id FROM film f WHERE f.title = new_movie_title);

    IF default_language_id IS NULL THEN
        RAISE EXCEPTION 'Default language "English" does not exist in the language table.';
    END IF;

    IF movie_id IS NOT NULL THEN
        RAISE EXCEPTION 'Movie already exists.';
    END IF;

    INSERT INTO film (title, release_year, language_id, rental_duration, rental_rate, replacement_cost)
    VALUES (new_movie_title, release_year, default_language_id, 3, 4.99, 19.99);
END;
$$ LANGUAGE plpgsql;

-- test case
SELECT new_movie('Star Trek: The Klingon Encounter');

