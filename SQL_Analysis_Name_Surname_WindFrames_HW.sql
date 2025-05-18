--Create a query for analyzing the annual sales data for the years 1999 to 2001, focusing on different sales channels and regions: 'Americas,' 'Asia,' and 'Europe.' 
-- AMOUNT_SOLD: This column should show the total sales amount for each sales channel
--% BY CHANNELS: In this column, we should display the percentage of total sales for each channel (e.g. 100% - total sales for Americas in 1999, 63.64% - percentage of sales for the channel “Direct Sales”)
WITH channel_sales AS (
SELECT 
    EXTRACT(YEAR FROM s.time_id) AS year,
    co.country_region,
    ch.channel_desc,
    SUM(s.amount_sold) AS amount_sold,
    ROUND(SUM(s.amount_sold) * 100.0 / 
          SUM(SUM(s.amount_sold)) OVER (PARTITION BY EXTRACT(YEAR FROM s.time_id), co.country_region), 2) AS percentage_by_channel
FROM sh.sales s
INNER JOIN customers c ON c.cust_id = s.cust_id
INNER JOIN countries co ON co.country_id = c.country_id
INNER JOIN channels ch ON ch.channel_id = s.channel_id
WHERE co.country_region IN ('Americas', 'Asia', 'Europe')
AND EXTRACT(YEAR FROM s.time_id) >= 1998
AND EXTRACT(YEAR FROM s.time_id) < 2002
GROUP BY 
    EXTRACT(YEAR FROM s.time_id),
    co.country_region,
    ch.channel_desc
),
--% PREVIOUS PERIOD: This column should display the same percentage values as in the '% BY CHANNELS' column but for the previous year
yearly_comparison AS (
    SELECT 
        year,
        country_region,
        channel_desc,
        amount_sold,
        percentage_by_channel,
        LAG(percentage_by_channel) OVER (
            PARTITION BY country_region, channel_desc 
            ORDER BY year
        ) AS last_year_percentage_by_channel,
        percentage_by_channel - LAG(percentage_by_channel) OVER (
            PARTITION BY country_region, channel_desc 
            ORDER BY year
        ) AS percentage_change
    FROM channel_sales
)
--% DIFF: This column should show the difference between the '% BY CHANNELS' and '% PREVIOUS PERIOD' columns, indicating the change in sales percentage from the previous year.
SELECT 
    country_region,
    year,
    channel_desc,
    amount_sold,
    percentage_by_channel,
    last_year_percentage_by_channel,
    ROUND(percentage_change, 2) AS difference_between_years
FROM yearly_comparison
WHERE  YEAR IN (1999,2000,2001)
ORDER BY 
    country_region ASC,
    YEAR ASC,
    channel_desc ASC;



--Generate a sales report for the 49th, 50th, and 51st weeks of 1999.
-- Generate a sales report for the 49th, 50th, and 51st weeks of 1999.
--Include a column named CUM_SUM to display the amounts accumulated during each week.
--Include a column named CENTERED_3_DAY_AVG to show the average sales for the previous, current, and following days 

WITH daily_sales AS (
    SELECT 
        EXTRACT(WEEK FROM time_id) AS week,
        time_id AS date,
        TO_CHAR(time_id, 'Day') AS day,
        SUM(amount_sold) AS daily_amount
    FROM sh.sales
    WHERE EXTRACT(WEEK FROM time_id) IN (49, 50, 51)
      AND EXTRACT(YEAR FROM time_id) = 1999
    GROUP BY time_id
)
SELECT 
    week,
    date,
    day,
    daily_amount,
    SUM(daily_amount) OVER (PARTITION BY week ORDER BY date) AS cum_sum,
    ROUND(AVG(daily_amount) OVER (
        PARTITION BY week 
        ORDER BY date
        ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
    ), 2) AS moving_avg
FROM daily_sales
ORDER BY date;



--Please provide 3 instances of utilizing window functions that include a frame clause, using RANGE, ROWS, and GROUPS modes. 
--Additionally, explain the reason for choosing a specific frame type for each example. 
--This can be presented as a single query or as three distinct queries.


-- calculates the total cost of promo by adding each days cost to the total 
-- way to graph yearly increase in total money spent doing promos 
-- or adding a where clause would let you split between promo types which in turn could showcase each promo type spending tendencies during a quarter/year/years
SELECT
    promo_id,
    promo_begin_date,
    promo_cost,
    SUM(promo_cost) OVER (
        ORDER BY promo_begin_date
        RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM sh.promotions;


-- calculates daily total cost
WITH daily_costs AS (
    SELECT
        time_id,
        SUM(unit_cost) AS daily_total_cost
    FROM costs
    GROUP BY time_id
)
-- calculates todays and the previous 2 days total cost
-- can be used  as a metric to cap spending within any 3 day window and help prioritize or delay transactions when nearing budget limits
SELECT
    time_id,
    daily_total_cost,
    SUM(daily_total_cost) OVER (
        ORDER BY time_id
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS running_3day_total
FROM sh.daily_costs
ORDER BY time_id;

-- get quarterly sales with comparison to previous N quarters
-- can be used for identifying seasonal patterns even with missing data periods
SELECT
    EXTRACT(YEAR FROM time_id) AS sales_year,
    EXTRACT(QUARTER FROM time_id) AS sales_quarter,
    SUM(amount_sold) AS quarterly_sales,
    AVG(SUM(amount_sold)) OVER (
        ORDER BY EXTRACT(YEAR FROM time_id), EXTRACT(QUARTER FROM time_id)
        GROUPS BETWEEN 1 PRECEDING AND 1 PRECEDING
    ) AS prev_quarter_sales,
    SUM(amount_sold) - AVG(SUM(amount_sold)) OVER (
        ORDER BY EXTRACT(YEAR FROM time_id), EXTRACT(QUARTER FROM time_id)
        GROUPS BETWEEN 1 PRECEDING AND 1 PRECEDING
    ) AS quarter_to_quarter_diff
FROM sh.sales
GROUP BY EXTRACT(YEAR FROM time_id), EXTRACT(QUARTER FROM time_id)
ORDER BY sales_year, sales_quarter;





