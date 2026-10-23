# E-commerce Order & Delivery Analytics

## 1. Business Problem

An e-commerce marketplace needs to understand delivery performance and its relationship with customer satisfaction.

This project analyzes historical transaction data to identify delivery patterns, evaluate their association with customer review scores, and identify potential opportunities for operational improvement.
## 2. Objectives
### Business Objectives
1. Measure on-time and late-delivery rates.
2. Examine the relationship between delivery delays and customer review scores.
3. Identify geographic or seller segments with unusually high delay rates.
### Technical Objectives
1. Design a relational database for transactional e-commerce data using PostgreSQL
2. Develop maintainable SQL queries and transformations.
3. Use Python for data exploration, processing, and validation.
4. Establishing a reproduciable analytical workflow that can later be extended into a data engineering pipeline.
## 3. Data Source
- Dataset: Olist Brazilian E-Commerce Dataset
- Source: Kaggle
- Format: CSV
- Contents: Orders, customers, products, payments, reviews, and related records.
## 4. Project Scope
### In Scope (V1 — Data Analysis)
- Data exploration and validation
- Relational database setup and data modeling
- SQL transformations and analysis
- Python-based exploration and validation
- Data quality checks
- Written findings and recommendations
- Technical documentaion
### Out of Scope (V1)
- Real-time data ingestion
- Cloud deployment
- Workflow orchestration
- Predictive machine learning
## 5. Deliverables
- PostgreSQL database schema
- SQL scripts and Python code
- Data dictionary and relationship diagram
- Analytical results and findings
- Data quality checks
- Architecture diagram and technical decision documentation
- Reproducible GitHub repository with setup instructions
## 6. Success Criteria
- Analytical metrics have documented definitions, grains, and inclusion criteria.
- Analytical tables satisfy their intended uniqueness requirements.
- Joins are validated to prevent unintended row multiplication.
- Data quality issues and relevant analytical limitations are documented.
- Findings address the project's three business objectives.
- Another developer can reproduce the analysis using documented instructions and permitted source data.
## 7. Known Questions and Considerations
The following questions will be investigated during data exploration:
- How should canceled, unavailable, or undelivered orders be handled?
- How should missing delivery timestamps and review scores be treated?
- What constitutes an on-time or late delivery?
- Which geographic and seller segments contain sufficient observations for meaningful comparisons?
- What conclusions can be supported by observational data without implying causation?
## 8.Future Development (V2 — Data Engineering)
- Automated data ingestion
- Incremental data loading
- Reusable data transformation pipelines
- Automated testing and monitoring
- Scheduling and workflow orchestration
- Optional cloud deployment and performance optimization