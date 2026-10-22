-- =====================================================
-- PROJECT: RETAIL STORE ANALYTICS
-- FILE: 04_analysis.sql
-- DATABASE: MySQL
-- PURPOSE: Answer business questions using SQL.
-- =====================================================

USE retail_store_analytics;


-- =====================================================
-- DATA PREPARATION QUESTION 1
-- Count rows in each cleaned table and count returns.
-- =====================================================

SELECT
    (SELECT COUNT(*) FROM customer) AS customer_rows,
    (SELECT COUNT(*) FROM prod_cat_info) AS product_category_rows,
    (SELECT COUNT(*) FROM transactions) AS transaction_rows,
    (SELECT COUNT(*)
     FROM transactions
     WHERE Qty < 0) AS return_transactions;


-- EXPLANATION:
-- 1. COUNT(*) counts the rows in each table.
-- 2. The subqueries independently count customers,
--    product-category combinations, and transactions.
-- 3. Qty < 0 identifies return transaction rows.
-- 4. The results verify the size of the cleaned dataset.
--
-- Expected results:
-- customer_rows = 5647
-- product_category_rows = 23
-- transaction_rows = 23040
-- return_transactions = 2177
-- =====================================================


-- =====================================================
-- DATA PREPARATION QUESTION 2
-- Find the date range covered by the dataset.
-- =====================================================

SELECT
    MIN(tran_date) AS first_transaction_date,
    MAX(tran_date) AS last_transaction_date,
    DATEDIFF(MAX(tran_date), MIN(tran_date)) AS days_between_dates,
    TIMESTAMPDIFF(
        MONTH,
        MIN(tran_date),
        MAX(tran_date)
    ) AS months_between_dates,
    TIMESTAMPDIFF(
        YEAR,
        MIN(tran_date),
        MAX(tran_date)
    ) AS years_between_dates
FROM transactions;


-- EXPLANATION:
-- 1. MIN(tran_date) returns the earliest transaction date.
-- 2. MAX(tran_date) returns the latest transaction date.
-- 3. DATEDIFF calculates the number of days between
--    the two dates, excluding the starting date.
-- 4. TIMESTAMPDIFF calculates the completed month and
--    year intervals between the dates.
-- 5. These results describe the period covered by the data.
--
-- Expected date range:
-- 25 January 2011 to 28 February 2014.
-- =====================================================


-- =====================================================
-- DATA PREPARATION QUESTION 3
-- Identify the product category containing the DIY
-- subcategory.
-- =====================================================

SELECT
    prod_cat,
    prod_subcat
FROM prod_cat_info
WHERE LOWER(TRIM(prod_subcat)) = 'diy';


-- EXPLANATION:
-- 1. prod_cat_info stores product categories and their
--    corresponding subcategories.
-- 2. LOWER converts the subcategory to lowercase.
-- 3. TRIM removes leading and trailing spaces.
-- 4. The WHERE condition finds the row matching DIY.
-- 5. The result identifies the parent product category.
-- =====================================================


-- =====================================================
-- END OF DATA PREPARATION QUESTIONS
-- Business questions follow in the next section.
-- =====================================================



-- =====================================================
-- BUSINESS QUESTION 4
-- Identify the most-used sales channel.
-- =====================================================

SELECT
    Store_type,
    COUNT(*) AS transaction_count
FROM transactions
GROUP BY Store_type
ORDER BY transaction_count DESC;


-- EXPLANATION:
-- 1. GROUP BY Store_type groups transactions by sales channel.
-- 2. COUNT(*) counts the transactions in each channel.
-- 3. ORDER BY transaction_count DESC ranks channels from
--    most-used to least-used.
-- 4. The first row identifies the channel with the highest
--    transaction count.
-- =====================================================


-- =====================================================
-- BUSINESS QUESTION 5A
-- Count customers by gender.
-- =====================================================

SELECT
    COALESCE(gender, 'Unknown') AS gender,
    COUNT(*) AS customer_count
FROM customer
GROUP BY gender
ORDER BY customer_count DESC;


-- EXPLANATION:
-- 1. COALESCE displays NULL gender values as 'Unknown'.
-- 2. COUNT(*) counts the customers in each gender group.
-- 3. GROUP BY creates a separate result for each gender.
-- 4. ORDER BY ranks groups by customer count.
-- 5. The result includes customers whose gender is missing.
-- =====================================================


-- =====================================================
-- BUSINESS QUESTION 5B
-- Find the city with the most customers.
-- =====================================================

SELECT
    COALESCE(city_code, -1) AS city_code,
    COUNT(*) AS customer_count
FROM customer
GROUP BY city_code
ORDER BY customer_count DESC;


-- EXPLANATION:
-- 1. city_code identifies the customer's city.
-- 2. COALESCE displays missing city codes as -1,
--    which represents Unknown in this output.
-- 3. COUNT(*) counts customers in each city group.
-- 4. ORDER BY sorts from the largest group to the smallest.
-- 5. The first row identifies the city with the most
--    customers, unless the first row is the Unknown group.
-- =====================================================



-- =====================================================
-- BUSINESS QUESTION 6A
-- List all subcategories under Books.
-- =====================================================

SELECT
    prod_cat,
    prod_subcat
FROM prod_cat_info
WHERE prod_cat = 'Books'
ORDER BY prod_subcat;


-- EXPLANATION:
-- 1. prod_cat_info contains product categories and subcategories.
-- 2. WHERE filters the records to the Books category.
-- 3. ORDER BY lists the subcategories alphabetically.
-- 4. The output identifies all subcategories under Books.
-- =====================================================


-- =====================================================
-- BUSINESS QUESTION 6B
-- Find the maximum quantity recorded in a transaction.
-- =====================================================

SELECT
    MAX(Qty) AS maximum_quantity_ordered
FROM transactions;


-- EXPLANATION:
-- 1. MAX(Qty) returns the largest quantity value
--    recorded in the cleaned transactions table.
-- 2. Negative quantities represent returns in this dataset.
-- 3. Since MAX selects the largest value, negative return
--    quantities will not determine the maximum if positive
--    quantities exist.
-- 4. The result gives the maximum recorded quantity in
--    a single transaction row.
-- =====================================================



-- =====================================================
-- BUSINESS QUESTION 7
-- Calculate net revenue from Electronics and Books.
-- =====================================================

SELECT
    p.prod_cat,
    SUM(t.total_amt) AS net_revenue
FROM transactions AS t
INNER JOIN prod_cat_info AS p
    ON t.prod_cat_code = p.prod_cat_code
   AND t.prod_subcat_code = p.prod_sub_cat_code
WHERE p.prod_cat IN ('Electronics', 'Books')
GROUP BY p.prod_cat
ORDER BY net_revenue DESC;


-- EXPLANATION:
-- 1. INNER JOIN connects transactions to product categories
--    using both category and subcategory codes.
-- 2. WHERE filters the data to Electronics and Books.
-- 3. SUM(total_amt) calculates net revenue, including
--    negative amounts from returns.
-- 4. GROUP BY reports net revenue separately for each category.
-- 5. ORDER BY ranks the two categories by net revenue.
--
-- Note:
-- The combined net revenue can be calculated by adding
-- the two category totals in the result.
-- =====================================================



-- =====================================================
-- BUSINESS QUESTION 8
-- Find customers with more than 10 non-return transactions.
-- =====================================================

SELECT
    c.customer_id,
    COUNT(*) AS purchase_transactions
FROM customer AS c
INNER JOIN transactions AS t
    ON c.customer_id = t.cust_id
WHERE t.Qty > 0
GROUP BY c.customer_id
HAVING COUNT(*) > 10
ORDER BY purchase_transactions DESC, c.customer_id;


-- EXPLANATION:
-- 1. INNER JOIN connects each transaction to its customer.
-- 2. WHERE t.Qty > 0 includes purchase rows and excludes
--    negative-quantity return rows.
-- 3. GROUP BY counts purchase transactions separately
--    for each customer.
-- 4. HAVING COUNT(*) > 10 keeps only customers with
--    more than 10 purchase transactions.
-- 5. ORDER BY lists customers with the most purchases first.
--
-- Expected result:
-- The list of customers with more than 10 purchase
-- transactions. The README reports 6 such customers;
-- verify this against your query output.
-- =====================================================



-- =====================================================
-- BUSINESS QUESTION 9
-- Calculate net revenue from Electronics and Clothing
-- at Flagship stores.
-- =====================================================

SELECT
    p.prod_cat,
    SUM(t.total_amt) AS net_revenue
FROM transactions AS t
INNER JOIN prod_cat_info AS p
    ON t.prod_cat_code = p.prod_cat_code
   AND t.prod_subcat_code = p.prod_sub_cat_code
WHERE t.Store_type = 'Flagship store'
  AND p.prod_cat IN ('Electronics', 'Clothing')
GROUP BY p.prod_cat
ORDER BY net_revenue DESC;


-- EXPLANATION:
-- 1. INNER JOIN maps each transaction to its product
--    category using both category and subcategory codes.
-- 2. WHERE filters transactions to Flagship stores and
--    the Electronics and Clothing categories.
-- 3. SUM(total_amt) calculates net revenue, including
--    negative return amounts.
-- 4. GROUP BY reports the revenue separately by category.
-- 5. ORDER BY ranks categories by net revenue.
--
-- The combined net revenue is the sum of both category
-- totals returned by this query.
-- =====================================================


-- =====================================================
-- BUSINESS QUESTION 10
-- Calculate net revenue from male customers for
-- Electronics, broken down by subcategory.
-- =====================================================

SELECT
    p.prod_subcat,
    SUM(t.total_amt) AS net_revenue
FROM transactions AS t
INNER JOIN customer AS c
    ON t.cust_id = c.customer_id
INNER JOIN prod_cat_info AS p
    ON t.prod_cat_code = p.prod_cat_code
   AND t.prod_subcat_code = p.prod_sub_cat_code
WHERE c.gender = 'M'
  AND p.prod_cat = 'Electronics'
GROUP BY p.prod_subcat
ORDER BY net_revenue DESC;


-- EXPLANATION:
-- 1. The first INNER JOIN connects transactions to customers.
-- 2. The second INNER JOIN identifies product subcategories
--    using both category and subcategory codes.
-- 3. WHERE filters for male customers and Electronics.
-- 4. SUM(total_amt) calculates net revenue, including
--    negative return amounts.
-- 5. GROUP BY calculates revenue separately for each
--    Electronics subcategory.
-- 6. ORDER BY ranks subcategories by net revenue.
-- =====================================================


-- =====================================================
-- BUSINESS QUESTION 11
-- Calculate sales and return percentages by subcategory.
-- Show the top 5 subcategories by gross sales value.
-- =====================================================

WITH subcategory_summary AS (
    SELECT
        p.prod_cat,
        p.prod_subcat,
        SUM(
            CASE
                WHEN t.Qty > 0 THEN t.total_amt
                ELSE 0
            END
        ) AS gross_sales,
        SUM(
            CASE
                WHEN t.Qty < 0 THEN ABS(t.total_amt)
                ELSE 0
            END
        ) AS return_value,
        SUM(
            CASE
                WHEN t.Qty > 0 THEN 1
                ELSE 0
            END
        ) AS sales_transactions,
        SUM(
            CASE
                WHEN t.Qty < 0 THEN 1
                ELSE 0
            END
        ) AS return_transactions
    FROM transactions AS t
    INNER JOIN prod_cat_info AS p
        ON t.prod_cat_code = p.prod_cat_code
       AND t.prod_subcat_code = p.prod_sub_cat_code
    GROUP BY
        p.prod_cat,
        p.prod_subcat
)
SELECT
    prod_cat,
    prod_subcat,
    gross_sales,
    return_value,
    ROUND(
        100.0 * gross_sales /
        NULLIF(SUM(gross_sales) OVER (), 0),
        2
    ) AS sales_percentage,
    ROUND(
        100.0 * return_value /
        NULLIF(SUM(return_value) OVER (), 0),
        2
    ) AS return_percentage,
    sales_transactions,
    return_transactions,
    ROUND(
        100.0 * return_transactions /
        NULLIF(sales_transactions, 0),
        2
    ) AS transaction_return_rate
FROM subcategory_summary
ORDER BY gross_sales DESC
LIMIT 5;


-- EXPLANATION:
-- 1. The CTE calculates gross sales value, return value,
--    positive-quantity transaction counts, and return counts
--    for each product subcategory.
-- 2. Gross sales include only positive-quantity rows.
-- 3. Return value uses ABS(total_amt) so returns are
--    displayed as positive values for easier comparison.
-- 4. Window functions calculate each subcategory's share
--    of total gross sales and total return value.
-- 5. transaction_return_rate is the number of return rows
--    divided by positive-quantity rows, expressed as a
--    percentage. It is a row-count rate, not a value rate.
-- 6. ORDER BY gross_sales DESC and LIMIT 5 return the
--    five subcategories with the highest gross sales.
--
-- Note:
-- Sales percentage and return percentage use different
-- denominators: total gross sales and total return value.
-- =====================================================


-- =====================================================
-- BUSINESS QUESTION 12
-- Calculate net revenue from customers aged 25–35
-- during the final 30 days of the dataset.
-- Use MAX(tran_date) as the dataset's reference date.
-- =====================================================

WITH dataset_end AS (
    SELECT MAX(tran_date) AS end_date
    FROM transactions
)
SELECT
    SUM(t.total_amt) AS net_revenue,
    MIN(t.tran_date) AS period_start_date,
    MAX(t.tran_date) AS period_end_date,
    COUNT(*) AS transaction_rows
FROM transactions AS t
INNER JOIN customer AS c
    ON t.cust_id = c.customer_id
CROSS JOIN dataset_end AS d
WHERE c.age_at_data_end BETWEEN 25 AND 35
  AND t.tran_date BETWEEN DATE_SUB(d.end_date, INTERVAL 29 DAY)
                      AND d.end_date;


-- EXPLANATION:
-- 1. The CTE finds the latest transaction date in the dataset.
-- 2. The query joins transactions to customer records.
-- 3. The age filter includes customers aged 25 through 35,
--    inclusive, using the age calculated at the data end date.
-- 4. DATE_SUB(..., INTERVAL 29 DAY) creates a 30-calendar-day
--    window when both boundary dates are included.
-- 5. SUM(total_amt) calculates net revenue, including returns.
-- 6. The output also displays the actual date range and the
--    number of transaction rows included.
-- =====================================================


-- =====================================================
-- BUSINESS QUESTION 13
-- Find the product category with the highest return
-- value during the final three months of the dataset.
-- =====================================================

WITH dataset_end AS (
    SELECT MAX(tran_date) AS end_date
    FROM transactions
)
SELECT
    p.prod_cat,
    SUM(ABS(t.total_amt)) AS return_value,
    COUNT(*) AS return_transactions
FROM transactions AS t
INNER JOIN prod_cat_info AS p
    ON t.prod_cat_code = p.prod_cat_code
   AND t.prod_subcat_code = p.prod_sub_cat_code
CROSS JOIN dataset_end AS d
WHERE t.Qty < 0
  AND t.tran_date > DATE_SUB(d.end_date, INTERVAL 3 MONTH)
  AND t.tran_date <= d.end_date
GROUP BY p.prod_cat
ORDER BY return_value DESC
LIMIT 1;


-- EXPLANATION:
-- 1. The CTE finds the latest transaction date.
-- 2. The joins identify the product category using both
--    category and subcategory codes.
-- 3. Qty < 0 filters for return transactions.
-- 4. ABS(total_amt) converts negative return amounts
--    into positive values for comparison.
-- 5. DATE_SUB(..., INTERVAL 3 MONTH) defines the
--    three-month lookback from the dataset end date.
-- 6. GROUP BY totals return value for each category.
-- 7. ORDER BY and LIMIT 1 return the category with
--    the highest return value.
-- =====================================================


-- =====================================================
-- BUSINESS QUESTION 14
-- Find the store type with the highest sales value
-- and sales quantity, excluding return transactions.
-- =====================================================

SELECT
    Store_type,
    SUM(total_amt) AS gross_sales_value,
    SUM(Qty) AS total_sales_quantity
FROM transactions
WHERE Qty > 0
GROUP BY Store_type
ORDER BY gross_sales_value DESC;


-- EXPLANATION:
-- 1. WHERE Qty > 0 includes only sales transactions,
--    excluding negative-quantity return rows.
-- 2. SUM(total_amt) calculates gross sales value by store.
-- 3. SUM(Qty) calculates the total quantity sold by store.
-- 4. GROUP BY produces one row for each store type.
-- 5. ORDER BY gross_sales_value DESC ranks store types
--    from highest to lowest gross sales value.
-- 6. Compare both output columns to identify which store
--    type leads in sales value and quantity.
-- =====================================================


-- =====================================================
-- BUSINESS QUESTION 15
-- Find product categories whose average transaction
-- revenue is above the overall average transaction revenue.
-- =====================================================

WITH category_revenue AS (
    SELECT
        p.prod_cat,
        AVG(t.total_amt) AS average_revenue
    FROM transactions AS t
    INNER JOIN prod_cat_info AS p
        ON t.prod_cat_code = p.prod_cat_code
       AND t.prod_subcat_code = p.prod_sub_cat_code
    GROUP BY p.prod_cat
),
overall_revenue AS (
    SELECT AVG(total_amt) AS overall_average_revenue
    FROM transactions
)
SELECT
    cr.prod_cat,
    ROUND(cr.average_revenue, 2) AS average_revenue,
    ROUND(orv.overall_average_revenue, 2)
        AS overall_average_revenue
FROM category_revenue AS cr
CROSS JOIN overall_revenue AS orv
WHERE cr.average_revenue > orv.overall_average_revenue
ORDER BY cr.average_revenue DESC;


-- EXPLANATION:
-- 1. category_revenue calculates the average transaction
--    amount separately for each product category.
-- 2. overall_revenue calculates the average transaction
--    amount across the entire cleaned transactions table.
-- 3. Both calculations include sales and returns, consistent
--    with using total_amt for net transaction revenue.
-- 4. The CROSS JOIN makes the overall average available
--    for comparison with every category.
-- 5. WHERE retains only categories whose average exceeds
--    the overall average.
-- 6. ORDER BY sorts qualifying categories from highest
--    average revenue to lowest.
-- =====================================================


-- =====================================================
-- BUSINESS QUESTION 16
-- Calculate average and total revenue by subcategory
-- for the top 5 product categories by quantity sold.
-- =====================================================

-- STEP 1: Calculate the total quantity sold for each
-- product category.
--
-- WHERE t.Qty > 0 excludes return transactions when
-- identifying the top 5 categories.
--
-- GROUP BY p.prod_cat calculates the quantity separately
-- for each product category.

WITH category_totals AS (
    SELECT
        p.prod_cat,
        SUM(t.Qty) AS category_quantity
    FROM transactions AS t
    INNER JOIN prod_cat_info AS p
        ON t.prod_cat_code = p.prod_cat_code
       AND t.prod_subcat_code = p.prod_sub_cat_code
    WHERE t.Qty > 0
    GROUP BY p.prod_cat
),

-- STEP 2: Select the five categories with the highest
-- positive quantity sold.
--
-- ORDER BY ... DESC sorts from highest to lowest.
-- LIMIT 5 returns only the top five categories.

top_5_categories AS (
    SELECT
        prod_cat,
        category_quantity
    FROM category_totals
    ORDER BY category_quantity DESC
    LIMIT 5
)

-- STEP 3: Calculate total and average transaction revenue
-- for each subcategory belonging to the top 5 categories.
--
-- SUM(t.total_amt) calculates total revenue.
-- AVG(t.total_amt) calculates average transaction revenue.
-- category_quantity displays the total positive quantity
-- for the parent category.
--
-- Note: Returns are included in these revenue calculations
-- because the final query does not filter out negative Qty.

SELECT
    p.prod_cat,
    p.prod_subcat,
    SUM(t.total_amt) AS total_revenue,
    AVG(t.total_amt) AS average_revenue,
    tc.category_quantity
FROM transactions AS t
INNER JOIN prod_cat_info AS p
    ON t.prod_cat_code = p.prod_cat_code
   AND t.prod_subcat_code = p.prod_sub_cat_code
INNER JOIN top_5_categories AS tc
    ON p.prod_cat = tc.prod_cat

-- STEP 4: Group the results by category and subcategory.
-- Each row represents one product subcategory.

GROUP BY
    p.prod_cat,
    p.prod_subcat,
    tc.category_quantity

-- STEP 5: Display categories by quantity sold,
-- then rank subcategories by total revenue within them.

ORDER BY
    tc.category_quantity DESC,
    total_revenue DESC;

-- =====================================================
-- END OF BUSINESS QUESTION 16
-- =====================================================



-- =====================================================
-- ADVANCED QUESTION 1: TOP CUSTOMERS IN EACH CITY
-- =====================================================

WITH customer_spending AS (
    SELECT
        c.city_code,
        c.customer_id,
        SUM(t.total_amt) AS net_spend
    FROM customer AS c
    INNER JOIN transactions AS t
        ON c.customer_id = t.cust_id
    GROUP BY
        c.city_code,
        c.customer_id
),
ranked_customers AS (
    SELECT
        city_code,
        customer_id,
        net_spend,
        RANK() OVER (
            PARTITION BY city_code
            ORDER BY net_spend DESC
        ) AS customer_rank
    FROM customer_spending
)
SELECT
    city_code,
    customer_id,
    net_spend,
    customer_rank
FROM ranked_customers
WHERE customer_rank <= 3
ORDER BY
    city_code,
    customer_rank,
    customer_id;

-- =====================================================
-- EXPLANATION OF ADVANCED QUESTION 1
-- =====================================================
-- Objective:
-- Find the top 3 customers in each city based on net spend.
--
-- 1. customer_spending CTE:
--    Calculates each customer's net spend by adding their
--    transaction amounts, including negative return amounts.
--
-- 2. ranked_customers CTE:
--    Uses RANK() to rank customers from highest to lowest
--    net spend within each city.
--
-- 3. PARTITION BY city_code:
--    Restarts the ranking separately for every city.
--
-- 4. ORDER BY net_spend DESC:
--    Gives rank 1 to the customer with the highest net spend.
--
-- 5. WHERE customer_rank <= 3:
--    Displays customers ranked in the top three positions.
--    Ties can result in more than three customers per city.
--
-- 6. Final ORDER BY:
--    Sorts the output by city, rank, and customer ID.
--
-- Business value:
-- Helps identify high-value customers in each city for
-- customer retention, loyalty programmes, and targeted
-- marketing campaigns.
-- =====================================================

-- END OF ADVANCED QUESTION 1



-- =====================================================
-- ADVANCED QUESTION 2: MONTH-ON-MONTH REVENUE GROWTH
-- =====================================================

WITH monthly_revenue AS (
    -- STEP 1: Calculate total revenue for each month.
    SELECT
        DATE_FORMAT(tran_date, '%Y-%m') AS sales_month,
        SUM(total_amt) AS monthly_revenue
    FROM transactions
    GROUP BY DATE_FORMAT(tran_date, '%Y-%m')
),
revenue_with_previous_month AS (
    -- STEP 2: Use LAG() to retrieve the previous month's revenue.
    SELECT
        sales_month,
        monthly_revenue,
        LAG(monthly_revenue) OVER (
            ORDER BY sales_month
        ) AS previous_month_revenue
    FROM monthly_revenue
)
-- STEP 3: Calculate the revenue change and growth percentage.
SELECT
    sales_month,
    monthly_revenue,
    previous_month_revenue,
    ROUND(
        monthly_revenue - previous_month_revenue,
        2
    ) AS revenue_change,
    ROUND(
        (monthly_revenue - previous_month_revenue)
        / NULLIF(previous_month_revenue, 0) * 100,
        2
    ) AS growth_percentage
FROM revenue_with_previous_month
ORDER BY sales_month;

-- =====================================================
-- EXPLANATION OF ADVANCED QUESTION 2
-- =====================================================
-- Objective:
-- Calculate monthly revenue and compare it with the
-- immediately preceding month.
--
-- 1. monthly_revenue CTE:
--    Groups transactions by year and month and calculates
--    the total revenue for each month.
--
-- 2. LAG(monthly_revenue):
--    Retrieves the revenue value from the previous row,
--    which represents the previous month in this result.
--
-- 3. revenue_change:
--    Calculates current-month revenue minus previous-month
--    revenue. A positive value indicates an increase.
--
-- 4. growth_percentage:
--    Calculates the percentage change relative to the
--    previous month's revenue.
--
-- 5. NULLIF(previous_month_revenue, 0):
--    Prevents division by zero.
--
-- 6. First month:
--    The previous-month revenue and growth percentage
--    will be NULL because no earlier month exists.
--
-- Business value:
-- Helps identify revenue increases, declines, and
-- month-to-month sales trends.
-- =====================================================

-- END OF ADVANCED QUESTION 2



-- =====================================================
-- ADVANCED QUESTION 3: RFM CUSTOMER SEGMENTATION
-- =====================================================

WITH dataset_reference AS (
    -- STEP 1: Find the final transaction date in the dataset.
    SELECT
        MAX(tran_date) AS reference_date
    FROM transactions
),
customer_rfm AS (
    -- STEP 2: Calculate Recency, Frequency, and Monetary value.
    SELECT
        t.cust_id AS customer_id,
        DATEDIFF(
            d.reference_date,
            MAX(t.tran_date)
        ) AS recency_days,
        COUNT(DISTINCT t.transaction_id) AS frequency,
        SUM(t.total_amt) AS monetary_value
    FROM transactions AS t
    CROSS JOIN dataset_reference AS d
    GROUP BY
        t.cust_id,
        d.reference_date
),
rfm_scores AS (
    -- STEP 3: Divide customers into five groups for each RFM metric.
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary_value,

        -- Lower recency days means a more recent purchase.
        NTILE(5) OVER (
            ORDER BY recency_days ASC
        ) AS recency_score,

        -- Higher frequency means more frequent transactions.
        NTILE(5) OVER (
            ORDER BY frequency ASC
        ) AS frequency_score,

        -- Higher monetary value means greater net spending.
        NTILE(5) OVER (
            ORDER BY monetary_value ASC
        ) AS monetary_score
    FROM customer_rfm
)
-- STEP 4: Display scores and assign indicative customer segments.
SELECT
    customer_id,
    recency_days,
    frequency,
    ROUND(monetary_value, 2) AS monetary_value,
    recency_score,
    frequency_score,
    monetary_score,
    CASE
        WHEN recency_score >= 4
             AND frequency_score >= 4
             AND monetary_score >= 4
            THEN 'Champions'
        WHEN frequency_score >= 4
             AND monetary_score >= 3
            THEN 'Loyal'
        WHEN recency_score <= 2
             AND frequency_score >= 3
            THEN 'At-risk'
        WHEN recency_score <= 2
             AND frequency_score <= 2
            THEN 'Lost'
        ELSE 'Other'
    END AS customer_segment
FROM rfm_scores
ORDER BY
    customer_id;

-- =====================================================
-- EXPLANATION OF ADVANCED QUESTION 3
-- =====================================================
-- Objective:
-- Segment customers using Recency, Frequency, and Monetary
-- (RFM) analysis.
--
-- 1. dataset_reference:
--    Finds the latest transaction date to use as a common
--    reference date for recency calculations.
--
-- 2. customer_rfm:
--    Recency = number of days since the customer's latest
--    transaction.
--    Frequency = number of distinct transactions.
--    Monetary = sum of transaction amounts, including
--    negative return amounts.
--
-- 3. NTILE(5):
--    Divides customers into five approximately equal-sized
--    groups for each metric.
--
-- 4. Recency score:
--    Customers with fewer days since their last purchase
--    receive higher scores because the ordering is ascending.
--
-- 5. Frequency and monetary scores:
--    Customers with more transactions or higher net spending
--    receive higher scores because their ordering is ascending.
--
-- 6. CASE expression:
--    Assigns indicative segments using the RFM scores.
--    Customers who do not match the listed rules are labelled
--    Other.
--
-- Important limitation:
--    These are simple illustrative segment rules. Inactive
--    customers with many historical purchases may be classified
--    as At-risk; segment definitions can be refined later.
--
-- Business value:
--    Helps prioritize loyal customers, recognize high-value
--    shoppers, and identify customers who may need re-engagement.
-- =====================================================

-- END OF ADVANCED QUESTION 3



-- =====================================================
-- ADVANCED QUESTION 3A: RFM CUSTOMER SEGMENT SUMMARY
-- =====================================================

-- Purpose:
-- Count the customers assigned to each RFM segment
-- and calculate the total monetary value of each segment.

WITH dataset_reference AS (
    SELECT MAX(tran_date) AS end_date
    FROM transactions
),
customer_rfm AS (
    SELECT
        t.cust_id AS customer_id,
        DATEDIFF(
            d.end_date,
            MAX(t.tran_date)
        ) AS recency_days,
        COUNT(DISTINCT t.transaction_id) AS frequency,
        SUM(t.total_amt) AS monetary_value
    FROM transactions AS t
    CROSS JOIN dataset_reference AS d
    GROUP BY
        t.cust_id,
        d.end_date
),
rfm_scores AS (
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary_value,
        NTILE(5) OVER (
            ORDER BY recency_days DESC
        ) AS recency_score,
        NTILE(5) OVER (
            ORDER BY frequency ASC
        ) AS frequency_score,
        NTILE(5) OVER (
            ORDER BY monetary_value ASC
        ) AS monetary_score
    FROM customer_rfm
),
segmented_customers AS (
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary_value,
        recency_score,
        frequency_score,
        monetary_score,
        CASE
            WHEN recency_score >= 4
                 AND frequency_score >= 4
                 AND monetary_score >= 4
                THEN 'Champions'
            WHEN frequency_score >= 4
                 AND monetary_score >= 3
                THEN 'Loyal'
            WHEN recency_score <= 2
                 AND frequency_score >= 3
                THEN 'At-risk'
            WHEN recency_score <= 2
                 AND frequency_score <= 2
                THEN 'Lost'
            ELSE 'Other'
        END AS customer_segment
    FROM rfm_scores
)
SELECT
    customer_segment,
    COUNT(*) AS customer_count,
    ROUND(SUM(monetary_value), 2) AS total_monetary_value
FROM segmented_customers
GROUP BY customer_segment
ORDER BY customer_count DESC;

-- Explanation:
-- 1. Finds the dataset's latest transaction date.
-- 2. Calculates recency, frequency and monetary value per customer.
-- 3. Uses NTILE(5) to assign scores from 1 to 5.
-- 4. Assigns each customer to a segment using the CASE rules.
-- 5. Summarizes the number of customers and their total
--    monetary value for each segment.
-- =====================================================


-- =====================================================
-- ADVANCED QUESTION 4: RETURN RATE BY PRODUCT CATEGORY
-- =====================================================

-- Purpose:
-- Calculate the number of return transactions and
-- positive-sale transactions for each product category.
-- Then calculate the return-to-sale transaction ratio.

SELECT
    p.prod_cat AS product_category,

    SUM(
        CASE
            WHEN t.Qty < 0 THEN 1
            ELSE 0
        END
    ) AS return_transactions,

    SUM(
        CASE
            WHEN t.Qty > 0 THEN 1
            ELSE 0
        END
    ) AS sales_transactions,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN t.Qty < 0 THEN 1
                ELSE 0
            END
        ) /
        NULLIF(
            SUM(
                CASE
                    WHEN t.Qty > 0 THEN 1
                    ELSE 0
                END
            ),
            0
        ),
        2
    ) AS return_rate_percentage

FROM transactions AS t
INNER JOIN prod_cat_info AS p
    ON t.prod_cat_code = p.prod_cat_code
   AND t.prod_subcat_code = p.prod_sub_cat_code

GROUP BY
    p.prod_cat

ORDER BY
    return_rate_percentage DESC;

-- Explanation:
-- 1. Joins transactions to product category information.
-- 2. Counts transactions with negative quantities as returns.
-- 3. Counts transactions with positive quantities as sales.
-- 4. Calculates the return-to-sale ratio as a percentage.
-- 5. Uses NULLIF to prevent division by zero.
-- 6. Sorts categories from highest to lowest return rate.
--
-- Note:
-- This is a transaction-count ratio, not a percentage
-- of units returned or revenue returned.
-- =====================================================


-- =====================================================
-- ADVANCED QUESTION 5: CUSTOMER COHORT ANALYSIS
-- =====================================================

-- Purpose:
-- Group customers by the month of their first purchase.
-- Then count how many customers from each cohort
-- made purchases in each subsequent calendar month.

WITH customer_first_purchase AS (
    SELECT
        cust_id,
        DATE_FORMAT(
            MIN(tran_date),
            '%Y-%m-01'
        ) AS cohort_month
    FROM transactions
    WHERE Qty > 0
    GROUP BY cust_id
),
customer_monthly_activity AS (
    SELECT DISTINCT
        cust_id,
        DATE_FORMAT(
            tran_date,
            '%Y-%m-01'
        ) AS activity_month
    FROM transactions
    WHERE Qty > 0
),
cohort_activity AS (
    SELECT
        cfp.cohort_month,
        cma.activity_month,
        COUNT(DISTINCT cma.cust_id) AS active_customers,
        TIMESTAMPDIFF(
            MONTH,
            STR_TO_DATE(cfp.cohort_month, '%Y-%m-%d'),
            STR_TO_DATE(cma.activity_month, '%Y-%m-%d')
        ) AS months_since_first_purchase
    FROM customer_first_purchase AS cfp
    INNER JOIN customer_monthly_activity AS cma
        ON cfp.cust_id = cma.cust_id
    GROUP BY
        cfp.cohort_month,
        cma.activity_month
)
SELECT
    cohort_month,
    activity_month,
    months_since_first_purchase,
    active_customers
FROM cohort_activity
ORDER BY
    cohort_month,
    months_since_first_purchase;

-- Explanation:
-- 1. customer_first_purchase finds each customer's first
--    positive-quantity purchase and assigns a cohort month.
-- 2. customer_monthly_activity records the months in which
--    each customer made a positive-quantity purchase.
-- 3. cohort_activity counts active customers for each
--    cohort and activity month.
-- 4. months_since_first_purchase measures the number of
--    calendar-month boundaries since the cohort began.
-- 5. The final output can be used to build a cohort
--    retention table or heatmap.
--
-- Note:
-- Only positive-quantity transactions are included,
-- so return-only activity is excluded from this analysis.
-- =====================================================

