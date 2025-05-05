--Create a new user with the username "rentaluser" and the password "rentalpassword". Give the user the ability to connect to the database but no other permissions.
CREATE USER rentaluser WITH PASSWORD 'rentalpassword';

GRANT CONNECT ON DATABASE dvdrental TO rentaluser;

--Grant "rentaluser" SELECT permission for the "customer" table. Сheck to make sure this permission works correctly—write a SQL query to select all customers.
GRANT SELECT ON customer TO rentaluser;

SELECT * FROM customer;

--Create a new user group called "rental" and add "rentaluser" to the group. 
CREATE GROUP  rental;

GRANT rental TO rentaluser;

SELECT * FROM pg_roles WHERE rolname = 'rentaluser';
--Grant the "rental" group INSERT and UPDATE permissions for the "rental" table. Insert a new row and update one existing row in the "rental" table under that role. 
GRANT INSERT, UPDATE ON rental TO rental;

-- to use serial in rental_id needs serial permissions
INSERT INTO rental (rental_id, inventory_id, customer_id, rental_date, return_date, staff_id)
VALUES (
	32308, -- random id 
    2,  
    1,  
    '2017-03-10 00:02:21.000 +0300',
    '2017-03-15 00:02:21.000 +0300',
    1 
)
RETURNING rental_id, customer_id, staff_id, inventory_id, rental_date;


--Revoke the "rental" group's INSERT permission for the "rental" table. Try to insert new rows into the "rental" table make sure this action is denied.
REVOKE INSERT ON rental FROM rental;
-- should fail
INSERT INTO rental (rental_id, inventory_id, customer_id, rental_date, return_date, staff_id)
VALUES (
	32309,
    1,  
    2,  
    '2017-03-10 00:02:21.000 +0300',
    '2017-03-15 00:02:21.000 +0300',
    3 
)
RETURNING rental_id, customer_id, staff_id, inventory_id, rental_date;

--Create a personalized role for any customer already existing in the dvd_rental database. The name of the role name must be client_{first_name}_{last_name} (omit curly brackets). The customer's payment and rental history must not be empty. 

CREATE ROLE client_ADAM_GOOCH;

WITH customer_cte AS (
    SELECT customer_id
    FROM public.customer
    WHERE UPPER(CONCAT('client_', first_name, '_', last_name)) = UPPER(CURRENT_USER)
)


-- give permisions
GRANT SELECT ON public.customer TO client_ADAM_GOOCH;
GRANT SELECT ON public.rental TO client_ADAM_GOOCH;
GRANT SELECT ON public.payment TO client_ADAM_GOOCH;



ALTER TABLE rental ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment ENABLE ROW LEVEL SECURITY;

-- Policies using the extracted name and surname


CREATE POLICY rental_policy
ON rental
USING (
    customer_id = (
        SELECT customer_id
        FROM public.customer
        WHERE UPPER(CONCAT('client_', first_name, '_', last_name)) = UPPER(CURRENT_USER)
    )
);

CREATE POLICY payment_policy
ON payment
USING (
    customer_id = (
        SELECT customer_id
        FROM public.customer
        WHERE UPPER(CONCAT('client_', first_name, '_', last_name)) = UPPER(CURRENT_USER)
    )
);



DROP POLICY IF EXISTS rental_policy ON rental;
DROP POLICY IF EXISTS payment_policy ON payment;

-- Switch to the customer user to test access
SET ROLE client_ADAM_GOOCH;

-- Query to check access
SELECT * FROM rental;
SELECT * FROM payment;

-- Switch back to the original role
SET ROLE postgres;