WITH first_purchase AS (
    SELECT 
        c.customer_unique_id,
        MIN(o.order_purchase_timestamp) AS datemin,
        FORMAT(MIN(o.order_purchase_timestamp), 'yyyy-MM') AS min_date
    FROM [dbo].[Customer] c
    INNER JOIN [dbo].[Orders] o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
),

next_order AS (
    SELECT 
        c.customer_unique_id,
        o.order_purchase_timestamp AS purchase_date,
        FORMAT(o.order_purchase_timestamp, 'yyyy-MM') AS next_date
    FROM [dbo].[Customer] c
    INNER JOIN [dbo].[Orders] o
        ON c.customer_id = o.customer_id
),

datediff_cte AS (
    SELECT 
        f.customer_unique_id,
        f.min_date,
        n.next_date,
        DATEDIFF(MONTH, f.datemin, n.purchase_date) AS cohort_index
    FROM first_purchase f
    INNER JOIN next_order n
        ON f.customer_unique_id = n.customer_unique_id
),

cohort_count AS (
    SELECT 
        min_date,
        cohort_index,
        COUNT(DISTINCT customer_unique_id) AS total_customers
    FROM datediff_cte
    GROUP BY 
        min_date, 
        cohort_index
),

cohort_size AS (
    SELECT 
        min_date,
        total_customers AS cohort_total
    FROM cohort_count
    WHERE cohort_index = 0
)

SELECT 
    min_date,
    [0],[1],[2],[3],[4],[5],[6],[7],[8],[9],
    [10],[11],[12],[13],[14],[15],[16],[17],[18],[19],[20]
FROM (
    SELECT 
        cc.min_date,
        cc.cohort_index,
        CAST(100.0 * cc.total_customers / cs.cohort_total AS DECIMAL(10,2)) AS retention_rate
    FROM cohort_count cc
    INNER JOIN cohort_size cs
        ON cc.min_date = cs.min_date
) AS source_data
PIVOT (
    MAX(retention_rate)
    FOR cohort_index IN (
        [0],[1],[2],[3],[4],[5],[6],[7],[8],[9],
        [10],[11],[12],[13],[14],[15],[16],[17],[18],[19],[20]
    )
) AS pivot_table
ORDER BY min_date;