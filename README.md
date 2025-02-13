# PostgreSQL Federation with Metabase Analytics

This project demonstrates a PostgreSQL federation setup using postgres_fdw (Foreign Data Wrapper) with three databases and Metabase for analytics visualization.

## Architecture

- **Database 1**: Contains customer and order data
- **Database 2**: Contains product and inventory data
- **Analytics Database**: Federates data from both source databases using postgres_fdw
- **Metabase**: Provides analytics and visualization layer

## Database Ports

- Database 1: localhost:5431
- Database 2: localhost:5432
- Analytics Database: localhost:5433
- Metabase: localhost:3000

## Credentials

### Database 1
- Database: source_db1
- User: user1
- Password: pass1

### Database 2
- Database: source_db2
- User: user2
- Password: pass2

### Analytics Database
- Database: analytics_db
- User: analytics_user
- Password: analytics_pass

## Setup

1. Start all services:
   ```bash
   docker-compose up -d
   ```

2. Wait for all services to be healthy (this may take a minute or two)

3. Access Metabase at http://localhost:3000

4. Configure Metabase:
   - Use the following credentials for the analytics database:
     - Host: analytics_db
     - Port: 5432
     - Database: analytics_db
     - Username: analytics_user
     - Password: analytics_pass

## Available Views

The analytics database provides two pre-configured views:

1. `customer_orders_summary`: Aggregates customer information with their order statistics
2. `product_inventory_summary`: Combines product information with inventory levels and values

## Testing the Setup

You can connect to any of the databases using psql or your preferred PostgreSQL client. Example:

```bash
# Connect to analytics database
psql -h localhost -p 5433 -U analytics_user -d analytics_db

# View available foreign tables
\det+

# Query the views
SELECT * FROM customer_orders_summary;
SELECT * FROM product_inventory_summary;
``` 