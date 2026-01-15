-- Clean transactions
DELETE FROM transactions
WHERE CustomerID IS NULL OR CustomerID = '';

ALTER TABLE transactions ADD COLUMN revenue DOUBLE;
UPDATE transactions
SET revenue = Quantity * UnitPrice;

-- Monthly revenue
DROP TABLE IF EXISTS monthly_revenue;
CREATE TABLE monthly_revenue AS
SELECT
    DATE_FORMAT(InvoiceDate, '%Y-%m-01') AS month,
    SUM(revenue) AS total_revenue
FROM transactions
GROUP BY DATE_FORMAT(InvoiceDate, '%Y-%m')
ORDER BY month;

-- Customer summary
DROP TABLE IF EXISTS customer_summary;
CREATE TABLE customer_summary AS
SELECT
    CustomerID,
    COUNT(DISTINCT InvoiceNo) AS total_orders,
    SUM(revenue) AS total_revenue,
    MAX(InvoiceDate) AS last_purchase_date
FROM transactions
GROUP BY CustomerID;

ALTER TABLE customer_summary ADD COLUMN churned INT;
UPDATE customer_summary
SET churned =
    CASE
        WHEN last_purchase_date < '2011-06-01' THEN 1
        ELSE 0
    END;

ALTER TABLE customer_summary ADD COLUMN customer_type VARCHAR(20);
UPDATE customer_summary
SET customer_type =
    CASE
        WHEN total_orders = 1 THEN 'One-time'
        ELSE 'Repeat'
    END;

-- Product loyalty
DROP TABLE IF EXISTS product_loyalty;
CREATE TABLE product_loyalty AS
WITH customer_product AS (
    SELECT
        StockCode,
        CustomerID,
        COUNT(DISTINCT DATE_FORMAT(InvoiceDate, '%Y-%m')) AS active_months
    FROM transactions
    GROUP BY StockCode, CustomerID
)
SELECT
    StockCode,
    COUNT(DISTINCT CustomerID) AS total_customers,
    COUNT(DISTINCT CASE WHEN active_months > 1 THEN CustomerID END) AS retained_customers,
    COUNT(DISTINCT CASE WHEN active_months = 1 THEN CustomerID END) AS churned_customers
FROM customer_product
GROUP BY StockCode;
