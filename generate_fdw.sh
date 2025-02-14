#!/bin/bash

# Exit on error
set -e

# Required environment variables
required_vars=("DB_HOST" "DB_PORT" "DB_NAME" "DB_USER" "DB_PASSWORD")
missing_vars=()

# Check for required environment variables
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        missing_vars+=("$var")
    fi
done

# If any required variables are missing, show error and exit
if [ ${#missing_vars[@]} -ne 0 ]; then
    echo "Error: Missing required environment variables:"
    printf '%s\n' "${missing_vars[@]}"
    echo
    echo "Please set the following environment variables:"
    echo "  export DB_HOST=your_host"
    echo "  export DB_PORT=your_port"
    echo "  export DB_NAME=your_database"
    echo "  export DB_USER=your_user"
    echo "  export DB_PASSWORD=your_password"
    exit 1
fi

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Create virtual environment if it doesn't exist
if [ ! -d "$SCRIPT_DIR/.venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv "$SCRIPT_DIR/.venv"
fi

# Activate virtual environment
source "$SCRIPT_DIR/.venv/bin/activate"

# Install requirements
echo "Installing dependencies..."
pip install -r "$SCRIPT_DIR/requirements.txt"

# Build connection string
CONNECTION_STRING="host=$DB_HOST port=$DB_PORT dbname=$DB_NAME user=$DB_USER password=$DB_PASSWORD"

# Additional arguments
EXTRA_ARGS=""
SERVER_NAME="$DB_NAME"  # Default server name to DB_NAME

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            EXTRA_ARGS="$EXTRA_ARGS --dry-run"
            shift
            ;;
        --debug)
            EXTRA_ARGS="$EXTRA_ARGS --debug"
            shift
            ;;
        --output=*)
            EXTRA_ARGS="$EXTRA_ARGS --output=${1#*=}"
            shift
            ;;
        --server-name=*)
            SERVER_NAME="${1#*=}"  # Update server name if provided
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            exit 1
            ;;
    esac
done

# Add server name to extra args
EXTRA_ARGS="$EXTRA_ARGS --server-name=$SERVER_NAME"

# Run the Python script
echo "Generating FDW DDL..."
python3 "$SCRIPT_DIR/generate_foreign_tables.py" "$CONNECTION_STRING" $EXTRA_ARGS

# Deactivate virtual environment
deactivate 