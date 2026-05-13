#!/bin/bash
# Wait for SQL Server to be ready
echo "Waiting for SQL Server to start..."
for i in {1..60}; do
    /opt/mssql-tools/bin/sqlcmd -S db -U sa -P StrongPass@123 -Q "SELECT 1" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "SQL Server is ready."
        break
    fi
    echo "SQL Server is not ready yet... ($i/60)"
    sleep 2
done

# Run SQL scripts in order
echo "Creating database..."
/opt/mssql-tools/bin/sqlcmd -S db -U sa -P StrongPass@123 -i /scripts/Create_DB_Fixed.sql

echo "Running Clean_DB.sql..."
/opt/mssql-tools/bin/sqlcmd -S db -U sa -P StrongPass@123 -i /scripts/Clean_DB.sql

echo "Running Data_ELearning_DB.sql..."
/opt/mssql-tools/bin/sqlcmd -S db -U sa -P StrongPass@123 -i /scripts/Data_ELearning_DB.sql

echo "Running TDH.sql..."
/opt/mssql-tools/bin/sqlcmd -S db -U sa -P StrongPass@123 -i /scripts/TDH.sql

echo "Running Data.sql..."
/opt/mssql-tools/bin/sqlcmd -S db -U sa -P StrongPass@123 -i /scripts/Data.sql

echo "Running fix_users.sql..."
/opt/mssql-tools/bin/sqlcmd -S db -U sa -P StrongPass@123 -i /scripts/fix_users.sql

echo "SQL Database initialization completed."
