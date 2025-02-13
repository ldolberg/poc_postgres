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

-- Create analytics views
CREATE VIEW customer_orders_summary AS
SELECT 
    c.customer_id,
    c.name,
    c.email,
    COUNT(o.order_id) as total_orders,
    SUM(o.amount) as total_spent
FROM customers_external c
LEFT JOIN orders_external o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name, c.email;

CREATE VIEW product_inventory_summary AS
SELECT 
    p.product_id,
    p.name,
    p.price,
    i.quantity,
    (p.price * i.quantity) as inventory_value
FROM products_external p
JOIN inventory_external i ON p.product_id = i.product_id; 