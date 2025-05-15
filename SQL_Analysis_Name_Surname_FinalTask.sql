-- Create a query to generate a report that identifies, for each channel and throughout the entire period, the regions with the highest quantity of products sold (quantity_sold). 
--The resulting report should include the following columns:
--CHANNEL_DESC
--COUNTRY_REGION
--SALES: This column will display the number of products sold (quantity_sold) with two decimal places.
--SALES %: This column will show the percentage of maximum sales in the region (as displayed in the SALES column) compared to the total sales for that channel. The sales percentage should be displayed with two decimal places and include the percent sign (%) at the end.
--Display the result in desccending order of SALES

WITH channel_region_sales AS (
    SELECT 
        ch.channel_desc,
        co.country_region,
        SUM(s.quantity_sold) AS region_sales,
        SUM(SUM(s.quantity_sold)) OVER (PARTITION BY ch.channel_desc) AS channel_total
    FROM sh.sales s 
    INNER JOIN sh.channels ch ON ch.channel_id = s.channel_id
    INNER JOIN sh.customers cust ON cust.cust_id = s.cust_id 
    INNER JOIN sh.countries co ON co.country_id = cust.country_id
    GROUP BY ch.channel_desc, co.country_region
),
ranked_regions AS (
    SELECT 
        channel_desc,
        country_region,
        region_sales,
        channel_total,
        ROW_NUMBER() OVER (PARTITION BY channel_desc ORDER BY region_sales DESC) AS region_rank
    FROM channel_region_sales
)
SELECT 
    channel_desc,
    country_region,
    ROUND(region_sales, 2) AS SALES,
    CONCAT(ROUND((region_sales / channel_total) * 100, 2), '%')  AS "SALES %"
FROM ranked_regions
WHERE region_rank = 1
ORDER BY region_sales DESC;


--Identify the subcategories of products with consistently higher sales from 1998 to 2001 compared to the previous year. 
--Determine the sales for each subcategory from 1998 to 2001.
--Calculate the sales for the previous year for each subcategory.
--Identify subcategories where the sales from 1998 to 2001 are consistently higher than the previous year.
--Generate a dataset with a single column containing the identified prod_subcategory values.


-- get category year total sum
WITH year_category_total AS (
  SELECT 
    EXTRACT(YEAR FROM s.time_id) AS YEAR,
    pro.prod_subcategory_desc AS category,
    SUM(s.quantity_sold) AS yearly_total_sales
  FROM sh.sales s 
  INNER JOIN sh.products pro ON pro.prod_id = s.prod_id 
  WHERE EXTRACT(YEAR FROM s.time_id) BETWEEN 1998 AND 2001
  GROUP BY EXTRACT(YEAR FROM s.time_id), pro.prod_subcategory_desc
),
-- get prev year sum
-- get a number of years that have higher total then last year ~  if(year> year-1) {+1} ignore first year cause  1997 = NULL
prev_year_sales AS (
SELECT
  YEAR,
  category,
  yearly_total_sales AS channel_total,
  LAG(yearly_total_sales) OVER (PARTITION BY category ORDER BY year) AS prev_year_sales,
  CASE 
      WHEN LAG(yearly_total_sales) OVER (PARTITION BY category ORDER BY year) IS NULL THEN NULL
      WHEN yearly_total_sales > LAG(yearly_total_sales) OVER (PARTITION BY category ORDER BY year) THEN 1
      ELSE 0
    END AS is_higher_than_prev
FROM year_category_total
)
-- get categories
-- checks if the case gives 3 for all 3 year comparisons
SELECT 
  category
FROM prev_year_sales
GROUP BY category
HAVING SUM(is_higher_than_prev) = 3 
ORDER BY category;



--Create a query to generate a sales report for the years 1999 and 2000, focusing on quarters and product categories. In the report you have to  analyze the sales of products from the categories 'Electronics,' 'Hardware,' and 'Software/Other,' across the distribution channels 'Partners' and 'Internet'.
--The resulting report should include the following columns:
--CALENDAR_YEAR: The calendar year
--CALENDAR_QUARTER_DESC: The quarter of the year
--PROD_CATEGORY: The product category
--SALES$: The sum of sales (amount_sold) for the product category and quarter with two decimal places
--DIFF_PERCENT: Indicates the percentage by which sales increased or decreased compared to the first quarter of the year. For the first quarter, the column value is 'N/A.' The percentage should be displayed with two decimal places and include the percent sign (%) at the end.
--CUM_SUM$: The cumulative sum of sales by quarters with two decimal places
--The final result should be sorted in ascending order based on two criteria: first by 'calendar_year,' then by 'calendar_quarter_desc'; and finally by 'sales' descending

-- get total sales by year quarter product 
WITH quarter_sales AS (
  SELECT 
    EXTRACT(YEAR FROM s.time_id) AS calendar_year,
    EXTRACT(QUARTER FROM  s.time_id) AS calendar_quarter_desc,
    pro.prod_category AS prod_category,
    ROUND(SUM(s.amount_sold), 2) AS sales$,
-- get the first quarter value
    FIRST_VALUE(SUM(s.amount_sold)) OVER (
      PARTITION BY EXTRACT(YEAR FROM s.time_id), pro.prod_category 
      ORDER BY EXTRACT(QUARTER FROM  s.time_id)
    ) AS q1_sales
  FROM sh.sales s
  INNER JOIN sh.products pro ON pro.prod_id = s.prod_id
  INNER JOIN sh.channels ch ON ch.channel_id = s.channel_id
  WHERE EXTRACT(YEAR FROM s.time_id) IN (1999, 2000)
    AND UPPER(pro.prod_category) IN (UPPER('Electronics'), UPPER('Hardware'), UPPER('Software/Other'))
    AND UPPER(ch.channel_desc) IN (UPPER('Partners'), UPPER('Internet'))
  GROUP BY 
    EXTRACT(YEAR FROM s.time_id),
    pro.prod_category,
    EXTRACT(QUARTER FROM  s.time_id)
),

-- get quarter total sum from all products
quarter_totals AS (
  SELECT
    calendar_year,
    calendar_quarter_desc,
    SUM(sales$) AS total_sales$
  FROM quarter_sales
  GROUP BY calendar_year, calendar_quarter_desc
),

-- get curent and all previous quarter total
cumulative_totals AS (
  SELECT
    calendar_year,
    calendar_quarter_desc,
    SUM(total_sales$) OVER (
      PARTITION BY calendar_year
      ORDER BY calendar_quarter_desc
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cum_sum$
  FROM quarter_totals
)

-- output
SELECT
  qs.calendar_year,
  qs.calendar_quarter_desc,
  qs.prod_category,
  qs.sales$,

  -- difference between current quarter product sales and first quarter product sales
  -- gives N/A to first quarter
  CASE 
    WHEN qs.calendar_quarter_desc = 1 THEN 'N/A'
    ELSE CONCAT(ROUND(((qs.sales$ - qs.q1_sales) / qs.q1_sales * 100), 2), '%')
  END AS diff_percent,

  ct.cum_sum$
FROM quarter_sales qs
INNER JOIN cumulative_totals ct
  ON qs.calendar_year = ct.calendar_year
 AND qs.calendar_quarter_desc = ct.calendar_quarter_desc
ORDER BY
  qs.calendar_year,
  qs.calendar_quarter_desc,
  qs.prod_category;


