
# ============================================================
# Olist E-Commerce Analytics
# End-to-end database pipeline
#
# Requires:
#   - PostgreSQL running locally
#   - psql available on PATH
#   - PostgreSQL authentication configured
#   - Original CSV files in data/raw/
# ============================================================

$ErrorActionPreference = "Stop"

$PROJECT_ROOT = (
    Resolve-Path (Join-Path $PSScriptRoot "..")
).Path

$DB_HOST = "127.0.0.1"
$DB_PORT = "5432"
$DB_USER = "postgres"
$DB_NAME = "olist_ecommerce"

# Ensure relative CSV paths work regardless of
# where the script was launched.
Push-Location $PROJECT_ROOT

try {
    function Invoke-SqlFiles {
        param(
            [string]$Database,
            [string[]]$Files
        )

        $arguments = @(
            "-X"
            "-U", $DB_USER
            "-h", $DB_HOST
            "-p", $DB_PORT
            "-d", $Database
            "-v", "ON_ERROR_STOP=1"
            "--single-transaction"
        )

        foreach ($file in $Files) {
            $arguments += @("-f", $file)
        }

        Write-Host "Running: $($Files -join ', ')"

        & psql @arguments

        if ($LASTEXITCODE -ne 0) {
            throw "SQL execution failed: $($Files -join ', ')"
        }
    }

    # --------------------------------------------------------
    # 1. Create database if missing
    # --------------------------------------------------------

    Write-Host "`n[1/5] Checking database..."

    $dbExists = & psql `
        -X -t -A `
        -U $DB_USER `
        -h $DB_HOST `
        -p $DB_PORT `
        -d postgres `
        -v ON_ERROR_STOP=1 `
        -c "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME';"

    if ($LASTEXITCODE -ne 0) {
        throw "Could not check database existence."
    }

    if ($dbExists -ne "1") {
        Write-Host "Creating database $DB_NAME..."

        & psql `
            -X `
            -U $DB_USER `
            -h $DB_HOST `
            -p $DB_PORT `
            -d postgres `
            -v ON_ERROR_STOP=1 `
            -f "sql/raw/00_create_database.sql"

        if ($LASTEXITCODE -ne 0) {
            throw "Database creation failed."
        }
    }
    else {
        Write-Host "Database already exists."
    }

    Invoke-SqlFiles -Database $DB_NAME -Files @(
        "sql/raw/01_create_schemas.sql"
        "sql/raw/02_create_raw_tables.sql"
    )

    # --------------------------------------------------------
    # 2. Raw ingestion and validation
    # --------------------------------------------------------

    Write-Host "`n[2/5] Loading raw data..."

    Invoke-SqlFiles -Database $DB_NAME -Files @(
        "sql/raw/03_load_raw_data.sql"
        "sql/raw/04_validate_raw_load.sql"
    )

    # --------------------------------------------------------
    # 3. Staging transformations and validation
    # --------------------------------------------------------

    Write-Host "`n[3/5] Building staging layer..."

    Invoke-SqlFiles -Database $DB_NAME -Files @(
        "sql/staging/01_create_tables.sql"
        "sql/staging/02_validate_tables.sql"
    )

    # --------------------------------------------------------
    # 4. Analytical models
    # --------------------------------------------------------

    Write-Host "`n[4/5] Building analytics models..."

    Invoke-SqlFiles -Database $DB_NAME -Files @(
        "sql/analytics/01_create_fact_orders.sql"
        "sql/analytics/02_create_fact_order_items.sql"
        "sql/analytics/03_create_dimensions.sql"
        "sql/analytics/04_create_order_review_summary.sql"
        "sql/analytics/05_create_delivery_performance.sql"
    )

    # --------------------------------------------------------
    # 5. Analytics validation
    # --------------------------------------------------------

    Write-Host "`n[5/5] Validating analytics..."

    Invoke-SqlFiles -Database $DB_NAME -Files @(
        "sql/analytics/06_validate_models.sql"
    )

    Write-Host "`nPipeline completed successfully."
}
finally {
    Pop-Location
}
