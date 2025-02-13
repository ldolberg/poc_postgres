-- Create the postgres_fdw extension
CREATE EXTENSION postgres_fdw;

-- Create foreign server for db1
CREATE SERVER db1_server
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'db1', port '5432', dbname 'source_db1');

-- Create foreign server for db2
CREATE SERVER db2_server
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'db2', port '5432', dbname 'source_db2');

-- Create user mappings
CREATE USER MAPPING FOR analytics_user
    SERVER db1_server
    OPTIONS (user 'user1', password 'pass1');

CREATE USER MAPPING FOR analytics_user
    SERVER db2_server
    OPTIONS (user 'user2', password 'pass2');

-- Create foreign tables for db1
CREATE FOREIGN TABLE customers_external (
    customer_id INTEGER,
    name VARCHAR(100),
    email VARCHAR(255),
    created_at TIMESTAMP
)
SERVER db1_server
OPTIONS (schema_name 'public', table_name 'customers');

CREATE FOREIGN TABLE orders_external (
    order_id INTEGER,
    customer_id INTEGER,
    amount DECIMAL(10,2),
    order_date TIMESTAMP
)
SERVER db1_server
OPTIONS (schema_name 'public', table_name 'orders');

-- Create foreign tables for db2
CREATE FOREIGN TABLE products_external (
    product_id INTEGER,
    name VARCHAR(100),
    price DECIMAL(10,2),
    created_at TIMESTAMP
)
SERVER db2_server
OPTIONS (schema_name 'public', table_name 'products');

CREATE FOREIGN TABLE inventory_external (
    inventory_id INTEGER,
    product_id INTEGER,
    quantity INTEGER,
    last_updated TIMESTAMP
)
SERVER db2_server
OPTIONS (schema_name 'public', table_name 'inventory');

-- Create enhanced analytics views

-- Customer order summary with time-based metrics
CREATE VIEW customer_orders_summary AS
SELECT 
    c.customer_id,
    c.name,
    c.email,
    COUNT(o.order_id) as total_orders,
    SUM(o.amount) as total_spent,
    AVG(o.amount) as avg_order_value,
    MAX(o.order_date) as last_order_date,
    MIN(o.order_date) as first_order_date,
    COUNT(CASE WHEN o.order_date >= CURRENT_TIMESTAMP - INTERVAL '30 days' THEN 1 END) as orders_last_30_days,
    SUM(CASE WHEN o.order_date >= CURRENT_TIMESTAMP - INTERVAL '30 days' THEN o.amount ELSE 0 END) as spent_last_30_days
FROM customers_external c
LEFT JOIN orders_external o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name, c.email;

-- Product inventory analysis
CREATE VIEW product_inventory_summary AS
SELECT 
    p.product_id,
    p.name,
    p.price,
    i.quantity,
    (p.price * i.quantity) as inventory_value,
    CASE 
        WHEN i.quantity = 0 THEN 'Out of Stock'
        WHEN i.quantity < 20 THEN 'Low Stock'
        WHEN i.quantity < 50 THEN 'Medium Stock'
        ELSE 'Good Stock'
    END as stock_status,
    i.last_updated as last_inventory_update,
    p.created_at as product_added_date
FROM products_external p
LEFT JOIN inventory_external i ON p.product_id = i.product_id;

-- Daily sales analysis
CREATE VIEW daily_sales_summary AS
SELECT 
    DATE_TRUNC('day', o.order_date) as sale_date,
    COUNT(DISTINCT o.customer_id) as unique_customers,
    COUNT(o.order_id) as total_orders,
    SUM(o.amount) as total_sales,
    AVG(o.amount) as avg_order_value
FROM orders_external o
GROUP BY DATE_TRUNC('day', o.order_date)
ORDER BY sale_date DESC;

-- Product performance analysis
CREATE VIEW product_performance AS
SELECT 
    p.name as product_name,
    p.price,
    i.quantity as current_stock,
    (p.price * i.quantity) as current_inventory_value,
    CASE 
        WHEN i.quantity = 0 THEN 'Urgent Reorder'
        WHEN i.quantity < 20 THEN 'Reorder Soon'
        WHEN i.quantity < 50 THEN 'Monitor Stock'
        ELSE 'Stock Adequate'
    END as inventory_status,
    p.created_at as product_launch_date,
    NOW() - p.created_at as product_age
FROM products_external p
LEFT JOIN inventory_external i ON p.product_id = i.product_id
ORDER BY current_inventory_value DESC; 