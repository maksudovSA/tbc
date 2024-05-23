

CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    customer_name VARCHAR(255) NOT NULL,
    email_address VARCHAR(255) UNIQUE NOT NULL,
    country VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
); --DISTRIBUTED BY (customer_id);
--2. Products Table
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    price NUMERIC(10, 2) NOT NULL,
    category VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ;--DISTRIBUTED BY (product_id);
--3. Sales Transactions Table
CREATE TABLE sales_transactions (
    transaction_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL,
    product_id INT NOT NULL,
    purchase_date DATE NOT NULL,
    quantity_purchased INT NOT NULL CHECK (quantity_purchased > 0),
    total_amount NUMERIC(10, 2), 
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
); --DISTRIBUTED BY (transaction_id);
SELECT * FROM  sales_transactions 
--4. Shipping Details Table
CREATE TABLE shipping_details (
    transaction_id INT PRIMARY KEY,
    shipping_date DATE NOT NULL,
    shipping_address VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (transaction_id) REFERENCES sales_transactions(transaction_id)
);--DISTRIBUTED BY (transaction_id);

--Insert Random ValuesInsert Random Values into Customers Table
INSERT INTO customers (customer_name, email_address, country)
SELECT
    md5(random()::text) AS customer_name,
    md5(random()::text) || '@example.com' AS email_address,
    CASE
        WHEN random() < 0.5 THEN 'USA'
        ELSE 'Canada'
    END AS country
FROM
    generate_series(1, 100); -- Insert 100 random customers
    
--Insert Random Values into Products Table

INSERT INTO products (product_name, price, category)
SELECT
    md5(random()::text) AS product_name,
    round(CAST(random() * 100 + 1 AS numeric), 2) AS price, -- Random price between 1 and 100
    CASE
        WHEN random() < 0.33 THEN 'Electronics'
        WHEN random() < 0.66 THEN 'Clothing'
        ELSE 'Home'
    END AS category
FROM
    generate_series(1, 50); -- Insert 50 random products

--Insert Random Values into Sales Transactions Table
INSERT INTO sales_transactions (customer_id, product_id, purchase_date, quantity_purchased)
SELECT
    (SELECT customer_id FROM customers ORDER BY random() LIMIT 1) AS customer_id,
    (SELECT product_id FROM products ORDER BY random() LIMIT 1) AS product_id,
    CURRENT_DATE - ((random() * 365)::int) AS purchase_date, -- Random date within the last year
    (random() * 10 + 1)::int AS quantity_purchased -- Random quantity between 1 and 10
FROM
    generate_series(1, 200); -- Insert 200 random sales transactions
    
--Insert Random Values into Shipping Details Table
INSERT INTO shipping_details (transaction_id, shipping_date, shipping_address, city, country)
SELECT
    transaction_id,
    purchase_date + ((random() * 10)::int) AS shipping_date, -- Random shipping date within 10 days of purchase
    md5(random()::text) AS shipping_address,
    CASE
        WHEN random() < 0.5 THEN 'New York'
        ELSE 'Toronto'
    END AS city,
    CASE
        WHEN random() < 0.5 THEN 'USA'
        ELSE 'Canada'
    END AS country
FROM
    sales_transactions
ORDER BY
    random()
LIMIT 200; -- Match the number of sales transactions



--total sales amount, 3 month moving average
WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', st.purchase_date) AS month,
        SUM(st.quantity_purchased * p.price) AS total_sales_amount,
        COUNT(st.transaction_id) AS total_transactions
    FROM
        sales_transactions st
    JOIN
        products p ON st.product_id = p.product_id
    GROUP BY
        DATE_TRUNC('month', st.purchase_date)
),
moving_avg_sales AS (
    SELECT
        month,
        total_sales_amount,
        total_transactions,
        AVG(total_sales_amount) OVER (
            ORDER BY month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS moving_avg_sales_amount
    FROM
        monthly_sales
)
SELECT
    month,
    total_sales_amount,
    total_transactions,
    moving_avg_sales_amount
FROM
    moving_avg_sales
ORDER BY
    month;