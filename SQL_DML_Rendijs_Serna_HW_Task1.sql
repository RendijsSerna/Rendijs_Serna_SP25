--Choose your top-3 favorite movies and add them to the 'film' table (films with the title Film1, Film2, etc - will not be taken into account and grade will be reduced)
-- Same query Add your favorite movies to any store's inventory.
-- Fill in rental rates with 4.99, 9.99 and 19.99 and rental durations with 1, 2 and 3 weeks respectively.
WITH insert_film AS (
    INSERT INTO film (
        title,
        description,
        release_year,
        language_id,
        rental_duration,
        rental_rate,
        length,
        replacement_cost
    )
    SELECT 
        new_films.title,
        new_films.description,
        new_films.release_year,
        new_films.language_id,
        new_films.rental_duration,
        new_films.rental_rate,
        new_films.length,
        new_films.replacement_cost
    FROM (
        SELECT 
            UPPER('Deadpool & Wolverine') AS title,
            'Deadpool is offered a place in the Marvel Cinematic Universe by the Time Variance Authority, but instead recruits a variant of Wolverine to save his universe from extinction.'
            AS description,
            2024 AS release_year,
            (SELECT l.language_id FROM language l WHERE LOWER(l.name) = LOWER('English')) AS language_id,
            1 AS rental_duration,
            4.99 AS rental_rate,
            128 AS length,
            4.99 AS replacement_cost
        UNION ALL
        SELECT 
            UPPER('Sonic the Hedgehog 3') AS title,
            'Sonic, Knuckles, and Tails reunite against a powerful new adversary, Shadow, a mysterious villain with powers unlike anything they have faced before. With their abilities outmatched, Team Sonic must seek out an unlikely alliance.'
            AS description,
            2024 AS release_year,
            (SELECT l.language_id FROM language l WHERE LOWER(l.name) = LOWER('English')) AS language_id,
            2 AS rental_duration,
            9.99 AS rental_rate,
            110 AS length,
            9.99 AS replacement_cost
        UNION ALL
        SELECT 
            UPPER('Kraven the Hunter') AS title,
            'Kraven''s complex relationship with his ruthless father, Nikolai Kravinoff, starts him down a path of vengeance with brutal consequences, motivating him to become not only the greatest hunter in the world, but also one of its most feared.'
            AS description,
            2024 AS release_year,
            (SELECT l.language_id FROM language l WHERE LOWER(l.name) = LOWER('English')) AS language_id,
            3 AS rental_duration,
            19.99 AS rental_rate,
            127 AS length,
            19.99 AS replacement_cost
    ) AS new_films
    WHERE NOT EXISTS (
        SELECT 1 FROM film WHERE film.title = new_films.title
    )
    RETURNING film_id
)

INSERT INTO inventory (film_id, store_id)
SELECT 
    f.film_id, 
    (SELECT store_id FROM store ORDER BY RANDOM() LIMIT 1) AS store_id
FROM insert_film f
WHERE NOT EXISTS (
    SELECT 1 
    FROM inventory i 
    WHERE i.film_id = f.film_id AND i.store_id = 2
)
RETURNING *;

--Add the actors who play leading roles in your favorite movies to the 'actor' and 'film_actor' tables (6 or more actors in total).  Actors with the name Actor1, Actor2, etc - will not be taken into account and grade will be reduced.

INSERT INTO actor (first_name, last_name)
SELECT UPPER('Ryan'), UPPER('Reynolds') 
WHERE NOT EXISTS (SELECT 1 FROM actor WHERE first_name = UPPER('Ryan') AND last_name = UPPER('Reynolds'));

INSERT INTO actor (first_name, last_name)
SELECT UPPER('Hugh'), UPPER('Jackman') 
WHERE NOT EXISTS (SELECT 1 FROM actor WHERE first_name = UPPER('Hugh') AND last_name = UPPER('Jackman'));

INSERT INTO film_actor (film_id, actor_id)
SELECT 
    f.film_id,
    a.actor_id
FROM 
    film f
JOIN
    actor a ON (a.last_name IN (UPPER('Reynolds'), UPPER('Jackman')) 
               AND a.first_name IN (UPPER('Ryan'), UPPER('Hugh')))
WHERE 
    f.title = UPPER('Deadpool & Wolverine')
    AND NOT EXISTS (
        SELECT 1 FROM film_actor fa
        WHERE fa.film_id = f.film_id AND fa.actor_id = a.actor_id
)
RETURNING *;


INSERT INTO actor (first_name, last_name)
SELECT UPPER('Jim'), UPPER('Carrey') 
WHERE NOT EXISTS (SELECT 1 FROM actor WHERE first_name = UPPER('Jim') AND last_name = UPPER('Carrey'));

INSERT INTO actor (first_name, last_name)
SELECT UPPER('Ben'), UPPER('Schwartz') 
WHERE NOT EXISTS (SELECT 1 FROM actor WHERE first_name = UPPER('Ben') AND last_name = UPPER('Schwartz'));

INSERT INTO film_actor (film_id, actor_id)
SELECT 
    f.film_id,
    a.actor_id
FROM 
    film f
JOIN
    actor a ON (a.last_name IN (UPPER('Carrey'), UPPER('Schwartz')) 
               AND a.first_name IN (UPPER('Jim'), UPPER('Ben')))
WHERE 
    f.title = UPPER('Sonic the Hedgehog 3')
    AND NOT EXISTS (
        SELECT 1 FROM film_actor fa
        WHERE fa.film_id = f.film_id AND fa.actor_id = a.actor_id
)
RETURNING *;


INSERT INTO actor (first_name, last_name)
SELECT UPPER('Fred'), UPPER('Hechinger') 
WHERE NOT EXISTS (SELECT 1 FROM actor WHERE first_name = UPPER('Fred') AND last_name = UPPER('Hechinger'));

INSERT INTO actor (first_name, last_name)
SELECT UPPER('Ariana'), UPPER('Debose') 
WHERE NOT EXISTS (SELECT 1 FROM actor WHERE first_name = UPPER('Ariana') AND last_name = UPPER('Debose'));

INSERT INTO film_actor (film_id, actor_id)
SELECT 
    f.film_id,
    a.actor_id
FROM 
    film f
JOIN
    actor a ON (a.last_name IN (UPPER('Hechinger'), UPPER('Debose')) 
               AND a.first_name IN (UPPER('Fred'), UPPER('Ariana')))
WHERE 
    f.title = UPPER('Kraven the Hunter')
    AND NOT EXISTS (
        SELECT 1 FROM film_actor fa
        WHERE fa.film_id = f.film_id AND fa.actor_id = a.actor_id
)
RETURNING *;


--Alter any existing customer in the database with at least 43 rental and 43 payment records. Change their personal data to yours (first name, last name, address, etc.). You can use any existing address from the "address" table. Please do not perform any updates on the "address" table, as this can impact multiple records with the same address.

WITH updated_customer AS (
    UPDATE customer 
    SET 
        store_id = (SELECT store_id FROM store ORDER BY random() LIMIT 1),
        first_name = UPPER('Rendijs'),
        last_name = UPPER('Serna'),
        email = UPPER('rendijsserna@gmail.com'),
        address_id = (SELECT address_id FROM address WHERE address = '191 Jos Azueta Parkway' LIMIT 1)
    WHERE customer_id = (
        SELECT c.customer_id
        FROM customer c
        INNER JOIN rental r ON r.customer_id = c.customer_id
        GROUP BY c.customer_id
        HAVING COUNT(DISTINCT r.rental_id) > 43
        LIMIT 1
    )
    AND NOT EXISTS (
        SELECT 1 FROM customer 
        WHERE first_name = UPPER('Rendijs') 
        AND last_name = UPPER('Serna')
    )
    RETURNING customer_id
),
--Remove any records related to you (as a customer) from all tables except 'Customer' and 'Inventory'
deleted_payments AS (
    DELETE FROM payment
    WHERE rental_id IN (
        SELECT rental_id FROM rental 
        WHERE customer_id IN (SELECT customer_id FROM updated_customer)
    )
    RETURNING rental_id
)
--Remove any records related to you (as a customer) from all tables except 'Customer' and 'Inventory'
DELETE FROM rental
WHERE customer_id IN (SELECT customer_id FROM updated_customer)
RETURNING *;

--Rent you favorite movies from the store they are in and pay for them (add corresponding records to the database to represent this activity)
WITH created_rental AS (
    INSERT INTO rental (inventory_id, customer_id, rental_date, return_date, staff_id)
    SELECT 
        i.inventory_id,
        c.customer_id,
        '2017-03-20 00:02:21.000 +0300',
        '2017-03-25 00:02:21.000 +0300',
        (SELECT staff_id FROM staff WHERE store_id = i.store_id ORDER BY RANDOM() LIMIT 1)
    FROM 
        inventory i
        INNER JOIN film f ON f.film_id = i.film_id
        CROSS JOIN customer c
    WHERE 
        (f.title = UPPER('Deadpool & Wolverine') OR 
         f.title = UPPER('Sonic the Hedgehog 3') OR 
         f.title = UPPER('Kraven the Hunter'))
        AND c.first_name = UPPER('rendijs') 
        AND c.last_name = UPPER('serna')
        AND NOT EXISTS (
            SELECT 1 
            FROM rental r 
            WHERE r.inventory_id = i.inventory_id
            AND (r.return_date IS NULL OR r.return_date > '2017-03-20 00:02:21.000 +0300')
        )
    RETURNING rental_id, customer_id, staff_id, inventory_id, rental_date
)
INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT 
    cr.customer_id,
    cr.staff_id,
    cr.rental_id, 
    f.rental_rate,
    cr.rental_date
FROM 
    created_rental cr
    JOIN inventory i ON cr.inventory_id = i.inventory_id
    JOIN film f ON i.film_id = f.film_id
RETURNING *;

COMMIT;

