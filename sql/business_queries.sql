New Wheels Business Analytics using SQL
Author: Aryaman Modi
Description: SQL queries for executive KPI reporting


Q1.a Total customers who placed orders
SELECT COUNT(DISTINCT customer_id) AS total_customers_who_placed_orders
FROM order_t;

Q1.b Customer distribution across states
SELECT
    c.state,
    COUNT(DISTINCT o.customer_id) AS customers_in_state
FROM order_t o
JOIN customer_t c
    ON o.customer_id = c.customer_id
GROUP BY c.state
ORDER BY customers_in_state DESC;

Q2 Top 5 preferred vehicle makers
SELECT
    p.vehicle_maker,
    COUNT(DISTINCT o.customer_id) AS customer_count
FROM order_t o
JOIN product_t p
    ON o.product_id = p.product_id
GROUP BY p.vehicle_maker
ORDER BY customer_count DESC
LIMIT 5;

Q3 Most preferred vehicle maker in each state
WITH maker_pref AS (
    SELECT
        c.state,
        p.vehicle_maker,
        COUNT(DISTINCT o.customer_id) AS cust_count,
        RANK() OVER (
            PARTITION BY c.state
            ORDER BY COUNT(DISTINCT o.customer_id) DESC
        ) AS rnk
    FROM order_t o
    JOIN customer_t c
        ON o.customer_id = c.customer_id
    JOIN product_t p
        ON o.product_id = p.product_id
    GROUP BY c.state, p.vehicle_maker
)
SELECT state, vehicle_maker, cust_count
FROM maker_pref
WHERE rnk = 1
ORDER BY state;

Q4 Average customer rating
DROP TABLE IF EXISTS temp_rating_map;

CREATE TEMP TABLE temp_rating_map AS
SELECT
    quarter_number,
    CASE customer_feedback
        WHEN 'Very Bad' THEN 1
        WHEN 'Bad' THEN 2
        WHEN 'Okay' THEN 3
        WHEN 'Good' THEN 4
        WHEN 'Very Good' THEN 5
    END AS rating_value
FROM order_t;

SELECT ROUND(AVG(rating_value),2) AS overall_avg_rating
FROM temp_rating_map;

SELECT
    quarter_number,
    ROUND(AVG(rating_value),2) AS avg_rating_per_quarter
FROM temp_rating_map
GROUP BY quarter_number
ORDER BY quarter_number;

Q5 Feedback distribution by quarter
SELECT
    quarter_number,
    ROUND(100.0 * SUM(CASE WHEN customer_feedback='Very Bad' THEN 1 ELSE 0 END)/COUNT(*),2) AS pct_very_bad,
    ROUND(100.0 * SUM(CASE WHEN customer_feedback='Bad' THEN 1 ELSE 0 END)/COUNT(*),2) AS pct_bad,
    ROUND(100.0 * SUM(CASE WHEN customer_feedback='Okay' THEN 1 ELSE 0 END)/COUNT(*),2) AS pct_okay,
    ROUND(100.0 * SUM(CASE WHEN customer_feedback='Good' THEN 1 ELSE 0 END)/COUNT(*),2) AS pct_good,
    ROUND(100.0 * SUM(CASE WHEN customer_feedback='Very Good' THEN 1 ELSE 0 END)/COUNT(*),2) AS pct_very_good
FROM order_t
GROUP BY quarter_number
ORDER BY quarter_number;

Q6 Orders by quarter
SELECT
    quarter_number,
    COUNT(order_id) AS total_orders
FROM order_t
GROUP BY quarter_number
ORDER BY quarter_number;

Q7 Net revenue and QoQ change
WITH revenue AS (
SELECT
    quarter_number,
    SUM(quantity * (vehicle_price * (1-discount/100.0))) AS net_revenue
FROM order_t
GROUP BY quarter_number
)
SELECT
    quarter_number,
    ROUND(net_revenue,2) AS net_revenue,
    ROUND(
        (net_revenue - LAG(net_revenue) OVER(ORDER BY quarter_number))
        / LAG(net_revenue) OVER(ORDER BY quarter_number) *100,
        2
    ) AS qoq_percent_change
FROM revenue
ORDER BY quarter_number;

Q8 Revenue and orders trend
SELECT
    quarter_number,
    SUM(quantity * (vehicle_price * (1-discount/100.0))) AS net_revenue,
    COUNT(order_id) AS total_orders
FROM order_t
GROUP BY quarter_number
ORDER BY quarter_number;

Q9 Average discount by credit card type
SELECT
    c.credit_card_type,
    ROUND(AVG(o.discount),2) AS avg_discount
FROM order_t o
JOIN customer_t c
    ON o.customer_id = c.customer_id
GROUP BY c.credit_card_type
ORDER BY avg_discount DESC;

Q10 Average shipping time by quarter
SELECT
    quarter_number,
    ROUND(AVG(julianday(ship_date)-julianday(order_date)),2) AS avg_days_to_ship
FROM order_t
WHERE ship_date IS NOT NULL
GROUP BY quarter_number
ORDER BY quarter_number;
