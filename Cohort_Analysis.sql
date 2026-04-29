DECLARE @cols AS NVARCHAR(MAX),
        @query AS NVARCHAR(MAX);


SELECT @cols = STRING_AGG(QUOTENAME(cohort_index), ',') 
               WITHIN GROUP (ORDER BY cohort_index)
FROM (
    SELECT DISTINCT DATEDIFF(MONTH, MIN_date_sub.datemin, o.order_purchase_timestamp) AS cohort_index
    FROM (
        SELECT c.customer_unique_id, MIN(o2.order_purchase_timestamp) AS datemin
        FROM [dbo].[Customer] c
        INNER JOIN [dbo].[Orders] o2 ON c.customer_id = o2.customer_id
        GROUP BY c.customer_unique_id
    ) AS MIN_date_sub
    INNER JOIN [dbo].[Customer] c ON c.customer_unique_id = MIN_date_sub.customer_unique_id
    INNER JOIN [dbo].[Orders] o ON c.customer_id = o.customer_id
) AS distinct_indexes;


SET @query = N'
WITH first_purchase AS (
    SELECT 
        c.customer_unique_id,
        MIN(o.order_purchase_timestamp) AS datemin,
        FORMAT(MIN(o.order_purchase_timestamp), ''yyyy-MM'') AS min_date
    FROM [dbo].[Customer] c
    INNER JOIN [dbo].[Orders] o ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
),
next_order AS (
    SELECT 
        c.customer_unique_id,
        o.order_purchase_timestamp AS purchase_date,
        FORMAT(o.order_purchase_timestamp, ''yyyy-MM'') AS next_date
    FROM [dbo].[Customer] c
    INNER JOIN [dbo].[Orders] o ON c.customer_id = o.customer_id
),
datediff_cte AS (
    SELECT 
        f.customer_unique_id,
        f.min_date,
        n.next_date,
        DATEDIFF(MONTH, f.datemin, n.purchase_date) AS cohort_index
    FROM first_purchase f
    INNER JOIN next_order n ON f.customer_unique_id = n.customer_unique_id
),
cohort_count AS (
    SELECT 
        min_date,
        cohort_index,
        COUNT(DISTINCT customer_unique_id) AS total_customers
    FROM datediff_cte
    GROUP BY min_date, cohort_index
),
cohort_size AS (
    SELECT 
        min_date,
        total_customers AS cohort_total
    FROM cohort_count
    WHERE cohort_index = 0
)
SELECT min_date, ' + @cols + '
FROM (
    SELECT 
        cc.min_date,
        cc.cohort_index,
        CAST(100.0 * cc.total_customers / cs.cohort_total AS DECIMAL(10,2)) AS retention_rate
    FROM cohort_count cc
    INNER JOIN cohort_size cs ON cc.min_date = cs.min_date
) AS source_data
PIVOT (
    MAX(retention_rate)
    FOR cohort_index IN (' + @cols + ')
) AS pivot_table
ORDER BY min_date;';

EXEC sp_executesql @query;
