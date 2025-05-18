--Create a query to produce a sales report highlighting the top customers with the highest sales across different sales channels. This report should list the top 5 customers for each channel. Additionally, calculate a key performance indicator (KPI) called 'sales_percentage,' which represents the percentage of a customer's sales relative to the total sales within their respective channel.
-- get sales for each customer within channel
WITH ChannelSales AS (
    SELECT
        sales.channel_id ,
        sales.cust_id ,
        SUM(sales.amount_sold ) AS total_sales
    FROM
        sh.sales
    GROUP BY
        channel_id, cust_id
),
-- get sales for each channel
ChannelTotalSales AS (
    SELECT
        channel_id ,
        SUM(total_sales) AS channel_total_sales
    FROM
        ChannelSales
    GROUP BY
        channel_id
),
-- rank customers within channel
RankedCustomers AS (
    SELECT
        cs.channel_id,
        cs.cust_id,
        cs.total_sales,
        RANK() OVER (PARTITION BY cs.channel_id ORDER BY cs.total_sales DESC) AS customer_rank,
        cts.channel_total_sales
    FROM
        ChannelSales cs
    JOIN
        ChannelTotalSales cts ON cs.channel_id = cts.channel_id
)
-- select the data + get kpi
SELECT
    (SELECT channel_desc FROM sh.channels ch WHERE rc.channel_id = ch.channel_id ),
    (SELECT cust_first_name FROM sh.customers c WHERE rc.cust_id = c.cust_id ),
    (SELECT cust_last_name FROM sh.customers c WHERE rc.cust_id = c.cust_id ),
    ROUND(total_sales, 2) AS total_sales,
    CONCAT(ROUND((total_sales / channel_total_sales) * 100, 4), '%') AS sales_percentage
FROM
    RankedCustomers rc
WHERE
    customer_rank <= 5
ORDER BY
    channel_id, total_sales DESC;


--Create a query to retrieve data for a report that displays the total sales for all products in the Photo category in the Asian region for the year 2000. Calculate the overall report total and name it 'YEAR_SUM'
-- get the data based on where and total
WITH product_sales AS (
    SELECT
        s.prod_id,
        EXTRACT(QUARTER FROM s.time_id) AS quarter,
        SUM(s.amount_sold) AS product_total
    FROM
        sh.sales s
    INNER JOIN sh.products p ON p.prod_id = s.prod_id
    INNER JOIN sh.customers c ON c.cust_id = s.cust_id
    INNER JOIN sh.countries cr ON cr.country_id = c.country_id
    WHERE
        p.prod_category = 'Photo'
        AND UPPER(cr.country_region) = 'ASIA'
        AND EXTRACT(YEAR FROM s.time_id) = 2000
    GROUP BY
        s.prod_id, quarter
),
-- calculate each quarter sales 
quarterly_totals AS (
    SELECT
        prod_id,
        SUM(CASE WHEN quarter = 1 THEN product_total ELSE 0 END) AS q1_total,
        SUM(CASE WHEN quarter = 2 THEN product_total ELSE 0 END) AS q2_total,
        SUM(CASE WHEN quarter = 3 THEN product_total ELSE 0 END) AS q3_total,
        SUM(CASE WHEN quarter = 4 THEN product_total ELSE 0 END) AS q4_total,
        SUM(product_total) AS year_total
    FROM
        product_sales
    GROUP BY
        prod_id
)
-- get the % of those sales from total
SELECT
    p.prod_name,
    ROUND(qt.q1_total, 2) AS q1_sales,
    ROUND(qt.q2_total, 2) AS q2_sales,
    ROUND(qt.q4_total, 2) AS q4_sales,
    ROUND(qt.year_total, 2) AS year_sum
FROM
    quarterly_totals qt
JOIN
    sh.products p ON p.prod_id = qt.prod_id
ORDER BY
    qt.year_total DESC;



--Create a query to generate a sales report for customers ranked in the top 300 based on total sales in the years 1998, 1999, and 2001. The report should be categorized based on sales channels, and separate calculations should be performed for each channel.
-- get sales per year
WITH YearlySales AS (
    SELECT
        sales.channel_id,
        sales.cust_id,
        EXTRACT(YEAR FROM sales.time_id) AS sale_year,
        SUM(sales.amount_sold) AS total_sales
    FROM
        sh.sales
    WHERE
        EXTRACT(YEAR FROM sales.time_id) IN (1998, 1999, 2001)
    GROUP BY
        sales.channel_id, sales.cust_id, sale_year
),
-- get customer data from one cte
CustomerData AS (
    SELECT
        c.cust_id,
        c.cust_first_name,
        c.cust_last_name
    FROM
        sh.customers c
    INNER JOIN sh.countries co ON co.country_id  = c.country_id
    WHERE
        c.cust_id IN (SELECT DISTINCT cust_id FROM YearlySales)
),
-- rank customers based on sales
RankedCustomers AS (
    SELECT
        ys.channel_id,
        ys.cust_id,
        ys.sale_year,
        ys.total_sales,
        RANK() OVER (PARTITION BY ys.channel_id, ys.sale_year ORDER BY ys.total_sales DESC) AS customer_rank
    FROM
        YearlySales ys
),
-- get only those customers who are in top 300 in all three years
QualifiedCustomers AS (
    SELECT
        cust_id
    FROM
        RankedCustomers
    WHERE
        customer_rank <= 300
    GROUP BY
        cust_id
    HAVING
        COUNT(DISTINCT sale_year) = 3
)
-- select data for top customers who qualified
SELECT
    (SELECT channel_desc FROM sh.channels ch WHERE rc.channel_id = ch.channel_id) AS channel_name,
    rc.cust_id,
    cd.cust_first_name,
    cd.cust_last_name,
    ROUND(rc.total_sales, 2) AS total_sales
FROM
    RankedCustomers rc
JOIN
    CustomerData cd ON rc.cust_id = cd.cust_id
JOIN
    QualifiedCustomers qc ON rc.cust_id = qc.cust_id
WHERE
    rc.customer_rank <= 300
ORDER BY
    rc.channel_id, rc.sale_year, rc.total_sales DESC;


--Create a query to generate a sales report for January 2000, February 2000, and March 2000 specifically for the Europe and Americas regions.
-- gets sales per subregion / date
WITH SalesData AS (
    SELECT
        TO_CHAR(s.time_id, 'YYYY-MM') AS sale_month,
        p.prod_category AS prod_category,
        SUM(CASE WHEN co.country_subregion LIKE '%Europe%' THEN s.amount_sold ELSE 0 END) AS europe_sales,
        SUM(CASE WHEN co.country_subregion LIKE '%America%' THEN s.amount_sold ELSE 0 END) AS america_sales
    FROM
        sh.sales s
    JOIN sh.customers c ON s.cust_id = c.cust_id
    JOIN sh.countries co ON c.country_id = co.country_id
    JOIN sh.products p ON s.prod_id = p.prod_id
    WHERE
        (co.country_subregion LIKE '%Europe%' OR co.country_subregion LIKE '%America%')
        AND EXTRACT(YEAR FROM s.time_id) = 2000
        AND EXTRACT(MONTH FROM s.time_id) IN (1, 2, 3)
    GROUP BY
        TO_CHAR(s.time_id, 'YYYY-MM'),
        p.prod_category
)
-- selects data from cte
SELECT
    sale_month,
    prod_category,
    ROUND(europe_sales, 2) AS europe_sales,
    ROUND(america_sales, 2) AS america_sales
FROM
    SalesData
-- ignores cases when eu + us = 0
WHERE europe_sales > 0 OR america_sales > 0
ORDER BY
    sale_month,
    prod_category ASC;
