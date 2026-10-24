# Load and validate the Olist raw data.
# Run from the repository root.
# Requires PostgreSQL psql and configured authentication.

$ErrorActionPreference = "Stop"

$psqlArgs = @(
    "-X"
    "-U", "postgres"
    "-h", "127.0.0.1"
    "-p", "5432"
    "-d", "olist_ecommerce"
    "-v", "ON_ERROR_STOP=1"
    "--single-transaction"
    "-f", "sql/03_load_raw_data.sql"
    "-f", "sql/04_validate_raw_load.sql"
)

& psql @psqlArgs 

if ($LASTEXITCODE -ne 0) {
    throw "Raw ingestion or validation failed."
}

Write-Host "Raw ingestion and validation completed successfully."