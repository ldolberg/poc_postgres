-- Create sample tables for source_db1
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(customer_id),
    amount DECIMAL(10,2),
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO customers (name, email) VALUES
    ('John Doe', 'john@example.com'),
    ('Jane Smith', 'jane@example.com'),
    ('Bob Wilson', 'bob@example.com'),
    ('Alice Johnson', 'alice@example.com'),
    ('Carlos Rodriguez', 'carlos@example.com'),
    ('Emma Davis', 'emma@example.com'),
    ('Michael Brown', 'michael@example.com'),
    ('Sarah Wilson', 'sarah@example.com');

-- Insert orders with different dates for better analytics
INSERT INTO orders (customer_id, amount, order_date) VALUES
    (1, 100.50, CURRENT_TIMESTAMP - INTERVAL '30 days'),
    (1, 200.75, CURRENT_TIMESTAMP - INTERVAL '15 days'),
    (1, 150.25, CURRENT_TIMESTAMP - INTERVAL '5 days'),
    (2, 300.00, CURRENT_TIMESTAMP - INTERVAL '20 days'),
    (2, 450.99, CURRENT_TIMESTAMP - INTERVAL '10 days'),
    (3, 199.99, CURRENT_TIMESTAMP - INTERVAL '25 days'),
    (3, 299.99, CURRENT_TIMESTAMP - INTERVAL '12 days'),
    (4, 750.00, CURRENT_TIMESTAMP - INTERVAL '8 days'),
    (5, 1200.50, CURRENT_TIMESTAMP - INTERVAL '3 days'),
    (6, 89.99, CURRENT_TIMESTAMP - INTERVAL '18 days'),
    (6, 149.99, CURRENT_TIMESTAMP - INTERVAL '7 days'),
    (7, 499.99, CURRENT_TIMESTAMP - INTERVAL '1 day'),
    (8, 899.99, CURRENT_TIMESTAMP); 