-- Create sample tables for source_db2
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    price DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE inventory (
    inventory_id SERIAL PRIMARY KEY,
    product_id INTEGER REFERENCES products(product_id),
    quantity INTEGER,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data for various product categories
INSERT INTO products (name, price, created_at) VALUES
    ('Laptop Pro X', 1299.99, CURRENT_TIMESTAMP - INTERVAL '60 days'),
    ('Smartphone Ultra', 899.99, CURRENT_TIMESTAMP - INTERVAL '45 days'),
    ('Wireless Headphones', 199.99, CURRENT_TIMESTAMP - INTERVAL '30 days'),
    ('4K Monitor', 499.99, CURRENT_TIMESTAMP - INTERVAL '25 days'),
    ('Gaming Mouse', 79.99, CURRENT_TIMESTAMP - INTERVAL '20 days'),
    ('Mechanical Keyboard', 149.99, CURRENT_TIMESTAMP - INTERVAL '15 days'),
    ('Tablet Pro', 649.99, CURRENT_TIMESTAMP - INTERVAL '10 days'),
    ('Smartwatch Elite', 299.99, CURRENT_TIMESTAMP - INTERVAL '5 days'),
    ('Wireless Charger', 39.99, CURRENT_TIMESTAMP),
    ('USB-C Hub', 59.99, CURRENT_TIMESTAMP);

-- Insert inventory data with different stock levels
INSERT INTO inventory (product_id, quantity, last_updated) VALUES
    (1, 25, CURRENT_TIMESTAMP - INTERVAL '2 days'),
    (2, 50, CURRENT_TIMESTAMP - INTERVAL '1 day'),
    (3, 100, CURRENT_TIMESTAMP - INTERVAL '12 hours'),
    (4, 15, CURRENT_TIMESTAMP - INTERVAL '3 days'),
    (5, 75, CURRENT_TIMESTAMP - INTERVAL '6 hours'),
    (6, 40, CURRENT_TIMESTAMP - INTERVAL '1 day'),
    (7, 30, CURRENT_TIMESTAMP - INTERVAL '2 days'),
    (8, 45, CURRENT_TIMESTAMP - INTERVAL '1 day'),
    (9, 150, CURRENT_TIMESTAMP),
    (10, 60, CURRENT_TIMESTAMP); 