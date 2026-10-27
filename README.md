
## Reproducing the Database Pipeline

### Prerequisites

- PostgreSQL 17
- Python 3.13
- PostgreSQL `psql` available on PATH
- PowerShell on Windows
- Local PostgreSQL server running on port 5432

### Source Data

Download the Olist Brazilian E-Commerce Public Dataset from Kaggle.

Place the nine original CSV files in `data/raw/`.

Source CSV files are excluded from Git to avoid committing large datasets.

### PostgreSQL Configuration

The pipeline uses:

- Host: `127.0.0.1`
- Port: `5432`
- User: `postgres`
- Database: `olist_ecommerce`

Configure PostgreSQL authentication locally before running the pipeline.

Do not commit passwords or credentials.

### Run the Pipeline

From the repository root:

```powershell
.\scripts\run_pipeline.ps1
```

The runner:

1. Creates the database if it does not exist.
2. Creates the required schemas and raw tables.
3. Loads and validates the source CSV data.
4. Rebuilds and validates staging tables.
5. Builds and validates analytical models.

The pipeline performs a full refresh and should not be used against a database containing unrelated data.

### Analytical Queries

Business analysis SQL files are located in `sql/analysis/`.

### Visualizations

Reproducible Python visualizations are developed in `notebooks/02_delivery_analysis.ipynb`.

Generated figures are saved in `outputs/figures/`.
