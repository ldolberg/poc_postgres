#!/usr/bin/env python3
import psycopg2
import sys
import argparse
import logging
from typing import Dict, List, Tuple, Optional


def setup_logging(debug: bool) -> None:
    """Configure logging based on debug mode."""
    level = logging.DEBUG if debug else logging.INFO
    logging.basicConfig(
        level=level,
        format='%(asctime)s - %(levelname)s - %(message)s'
    )


def get_tables_and_columns(conn) -> Dict[str, List[Tuple]]:
    """
    Query the public schema for base tables and return a dictionary:
    { table_name: [(column_name, data_type, character_maximum_length), ...] }
    """
    cursor = None
    try:
        cursor = conn.cursor()
        logging.debug("Querying for tables in public schema...")
        cursor.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public' AND table_type = 'BASE TABLE';
        """)
        tables = cursor.fetchall()
        logging.debug(f"Found {len(tables)} tables")

        table_dict = {}
        for (table_name,) in tables:
            logging.debug(f"Fetching columns for table: {table_name}")
            cursor.execute("""
                SELECT column_name, data_type, character_maximum_length
                FROM information_schema.columns
                WHERE table_schema = 'public' AND table_name = %s
                ORDER BY ordinal_position;
            """, (table_name,))
            columns = cursor.fetchall()
            logging.debug(f"Found {len(columns)} columns in {table_name}")
            table_dict[table_name] = columns
        return table_dict
    except psycopg2.Error as e:
        logging.error(f"Database error: {str(e)}")
        raise
    finally:
        if cursor:
            cursor.close()


def map_data_type(data_type: str, char_max: Optional[int]) -> str:
    """
    Map information_schema data types into Postgres DDL types.
    """
    dt = data_type.lower()
    logging.debug(f"Mapping data type: {data_type} (max length: {char_max})")
    
    if dt in ['character varying', 'varchar']:
        return f"VARCHAR({char_max})" if char_max else "VARCHAR"
    elif dt in ['character', 'char']:
        return f"CHAR({char_max})" if char_max else "CHAR"
    elif dt in ['integer', 'int']:
        return "INTEGER"
    elif dt == 'double precision':
        return "DOUBLE PRECISION"
    elif dt.startswith('timestamp'):
        if 'without' in dt:
            return "TIMESTAMP"
        else:
            return "TIMESTAMPTZ"
    elif dt == 'numeric':
        return "NUMERIC"
    elif dt == 'boolean':
        return "BOOLEAN"
    elif dt == 'text':
        return "TEXT"
    elif dt == 'json':
        return "JSON"
    elif dt == 'jsonb':
        return "JSONB"
    elif dt == 'date':
        return "DATE"
    elif dt == 'time':
        return "TIME"
    else:
        logging.warning(f"Unknown data type: {data_type}, using as is")
        return dt.upper()


def generate_foreign_table_ddl(table_name: str, columns: List[Tuple], 
                             server_name: str, alias_suffix: str = '_external') -> str:
    """
    Generate the CREATE FOREIGN TABLE command given a table's column definitions.
    """
    logging.debug(f"Generating DDL for table: {table_name}")
    ddl = f"CREATE FOREIGN TABLE {server_name}_{table_name}{alias_suffix} (\n"
    col_defs = []
    for col in columns:
        col_name, data_type, char_max = col
        mapped_type = map_data_type(data_type, char_max)
        col_defs.append(f"    {col_name} {mapped_type}")
        logging.debug(f"Added column: {col_name} {mapped_type}")
    ddl += ",\n".join(col_defs)
    ddl += "\n)\n"
    ddl += f"SERVER {server_name}\n"
    ddl += f"OPTIONS (schema_name 'public', table_name '{table_name}');\n"
    return ddl


def parse_conn_str(conn_str: str) -> Dict[str, str]:
    """
    Parse a simple connection string of the form:
    host=... port=... dbname=... user=... password=...
    into a dictionary.
    """
    logging.debug(f"Parsing connection string (password hidden)")
    parts = conn_str.strip().split()
    params = {}
    for part in parts:
        if '=' in part:
            key, value = part.split('=', 1)
            if key != 'password':
                logging.debug(f"Found parameter: {key}={value}")
            params[key] = value
    return params


def main(db_conn_str: str, dry_run: bool, output_file: Optional[str], 
         server_name: str, debug: bool) -> None:
    setup_logging(debug)
    logging.info("Starting DDL generation process")
    ddl_script = ""

    try:
        # Create FDW extension.
        logging.debug("Adding FDW extension creation")
        ddl_script += "-- Create the postgres_fdw extension\n"
        ddl_script += "CREATE EXTENSION IF NOT EXISTS postgres_fdw;\n\n"

        # Parse connection string parameters.
        params = parse_conn_str(db_conn_str)
        logging.info(f"Connecting to database: {params.get('dbname')} at {params.get('host')}:{params.get('port')}")

        ddl_script += f"-- Create foreign server for source database\n"
        ddl_script += f"CREATE SERVER {server_name}\n"
        ddl_script += "    FOREIGN DATA WRAPPER postgres_fdw\n"
        ddl_script += f"    OPTIONS (host '{params.get('host', 'localhost')}', port '{params.get('port', '5432')}', dbname '{params.get('dbname', 'source_db')}');\n\n"

        ddl_script += "-- Create user mapping\n"
        ddl_script += f"CREATE USER MAPPING FOR analytics_user\n"
        ddl_script += f"    SERVER {server_name}\n"
        ddl_script += f"    OPTIONS (user '{params.get('user','user')}', password '{params.get('password','password')}');\n\n"

        # Test database connection
        logging.info("Testing database connection...")
        conn = psycopg2.connect(db_conn_str)
        logging.info("Database connection successful")

        # Get table information
        tables = get_tables_and_columns(conn)
        logging.info(f"Retrieved information for {len(tables)} tables")
    
        # Generate foreign table definitions
        ddl_script += "-- Create foreign tables\n"
        for table, columns in tables.items():
            ddl_script += generate_foreign_table_ddl(table, columns, server_name, alias_suffix="_external") + "\n"

        conn.close()
        logging.info("Database connection closed")

        # Output the results
        if dry_run:
            logging.info("Dry run mode - printing DDL to stdout")
            print(ddl_script)
        else:
            out_file = output_file if output_file else "generated_ddl.sql"
            logging.info(f"Writing DDL to file: {out_file}")
            with open(out_file, "w") as f:
                f.write(ddl_script)
            logging.info(f"DDL script written successfully to {out_file}")

    except psycopg2.Error as e:
        logging.error(f"Database error: {str(e)}")
        sys.exit(1)
    except Exception as e:
        logging.error(f"Unexpected error: {str(e)}")
        sys.exit(1)


def parse_arguments():
    parser = argparse.ArgumentParser(
        description='Generate foreign table DDL from a source database schema.',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Example usage:
  %(prog)s "host=localhost port=5432 dbname=mydb user=myuser password=mypass" --dry-run
  %(prog)s "host=localhost port=5432 dbname=mydb user=myuser password=mypass" --output=myfile.sql
  %(prog)s "host=localhost port=5432 dbname=mydb user=myuser password=mypass" --server-name=myserver --debug
        """
    )
    parser.add_argument('db_conn', type=str, 
                       help='Connection string for the source database')
    parser.add_argument('--dry-run', action='store_true',
                       help='Output the generated DDL without writing to a file')
    parser.add_argument('--output', type=str, default=None,
                       help='Output file to write the generated DDL script (ignored in dry run mode)')
    parser.add_argument('--server-name', type=str, default='source_server',
                       help='Name of the foreign server to create')
    parser.add_argument('--debug', action='store_true',
                       help='Enable debug logging')
    return parser.parse_args()


if __name__ == '__main__':
    args = parse_arguments()
    main(args.db_conn, args.dry_run, args.output, args.server_name, args.debug) 