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

-- Insert sample data
INSERT INTO products (name, price) VALUES
    ('Laptop', 999.99),
    ('Smartphone', 599.99),
    ('Headphones', 99.99);

INSERT INTO inventory (product_id, quantity) VALUES
    (1, 50),
    (2, 100),
    (3, 200); 