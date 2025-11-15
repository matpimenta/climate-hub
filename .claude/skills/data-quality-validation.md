---
name: data-quality-validation
description: "Generate comprehensive data quality validation checks and monitoring queries for data pipelines and warehouse tables"
---

# Data Quality Validation - Automated Quality Assurance for Data Pipelines

## Purpose
This skill generates comprehensive data quality validation checks, monitoring queries, and quality assurance frameworks for data warehouses and pipelines. It produces SQL-based validation queries, quality metrics, and alerting strategies to ensure data accuracy, completeness, consistency, and timeliness.

## Input Parameters

**Required:**
- `table_reference` (string): Full table reference in format "project.dataset.table"
- `validation_types` (array): Types of validation checks needed. Options:
  - "completeness" - null checks, missing values, required fields
  - "uniqueness" - duplicate detection, primary key validation
  - "consistency" - referential integrity, cross-table validation
  - "accuracy" - value range checks, format validation, business rules
  - "timeliness" - data freshness, SLA monitoring, lag detection

**Optional:**
- `schema_info` (object): Table schema information
  - `primary_keys` (array): Primary key column(s)
  - `foreign_keys` (array): Foreign key relationships to other tables
  - `required_fields` (array): Fields that must not be null
  - `unique_fields` (array): Fields that must be unique
- `business_rules` (array): Custom validation rules
  - Each rule: `{"field": "column_name", "rule_type": "range|format|enum", "rule_spec": "specification"}`
- `sla_requirements` (object): Service level requirements
  - `max_age_hours` (number): Maximum acceptable data age
  - `min_row_count` (number): Minimum expected row count for recent period
  - `update_frequency` (string): Expected update frequency
- `alert_thresholds` (object): When to trigger alerts
  - `null_percentage_threshold` (number): Max acceptable null percentage (default: 5)
  - `duplicate_threshold` (number): Max acceptable duplicate count (default: 0)
  - `freshness_threshold_hours` (number): Max acceptable data age (default: 24)
- `monitoring_period` (string): Time window for checks (default: "24 hours")

## Output Format

```json
{
  "validation_suite": {
    "table": "project.dataset.table",
    "generated_at": "ISO-8601 timestamp",
    "total_checks": 12
  },
  "completeness_checks": [
    {
      "check_name": "null_value_detection",
      "description": "Detect null values in required fields",
      "sql_query": "SELECT ...",
      "pass_criteria": "All required fields have <5% null values",
      "alert_on": "null_percentage > threshold"
    }
  ],
  "uniqueness_checks": [
    {
      "check_name": "duplicate_detection",
      "description": "Identify duplicate records",
      "sql_query": "SELECT ...",
      "pass_criteria": "Zero duplicate primary key values",
      "alert_on": "duplicate_count > 0"
    }
  ],
  "consistency_checks": [
    {
      "check_name": "referential_integrity",
      "description": "Validate foreign key relationships",
      "sql_query": "SELECT ...",
      "pass_criteria": "All foreign keys reference valid records",
      "alert_on": "orphaned_records > 0"
    }
  ],
  "accuracy_checks": [
    {
      "check_name": "value_range_validation",
      "description": "Ensure values are within acceptable ranges",
      "sql_query": "SELECT ...",
      "pass_criteria": "All values within specified ranges",
      "alert_on": "out_of_range_count > 0"
    }
  ],
  "timeliness_checks": [
    {
      "check_name": "data_freshness",
      "description": "Monitor data recency",
      "sql_query": "SELECT ...",
      "pass_criteria": "Latest data within SLA timeframe",
      "alert_on": "hours_since_update > threshold"
    }
  ],
  "monitoring_dashboard_query": "Combined query for dashboard visualization",
  "scheduled_check_framework": {
    "recommended_schedule": "Every 1 hour",
    "implementation_options": [
      "Cloud Scheduler + Cloud Functions",
      "Dataform assertions",
      "Airflow data quality operators",
      "dbt tests"
    ]
  },
  "alert_configuration": {
    "recommended_channels": ["email", "slack", "pagerduty"],
    "severity_levels": {
      "critical": "Conditions requiring immediate action",
      "warning": "Conditions requiring investigation",
      "info": "Informational metrics"
    }
  }
}
```

## Behavior

This skill generates validation checks following these steps:

1. **Completeness Analysis**:
   - Generates null value detection queries for all required fields
   - Creates missing value percentage calculations
   - Produces row count validation for expected data volumes
   - Checks for empty string or default values that should be populated

2. **Uniqueness Validation**:
   - Generates duplicate detection queries for primary keys
   - Creates unique constraint validation for specified fields
   - Produces queries to find duplicate combinations
   - Calculates uniqueness percentages for high-cardinality fields

3. **Consistency Checking**:
   - Generates referential integrity queries for foreign keys
   - Creates cross-table validation queries
   - Produces logical consistency checks (e.g., end_date >= start_date)
   - Validates enum values against allowed lists

4. **Accuracy Verification**:
   - Generates value range validation (min/max bounds)
   - Creates format validation (regex patterns, data types)
   - Produces business rule validation queries
   - Validates calculated fields against source data

5. **Timeliness Monitoring**:
   - Generates data freshness queries (time since last update)
   - Creates lag monitoring for streaming or incremental loads
   - Produces SLA compliance queries
   - Monitors partition completeness for time-series data

6. **Monitoring Framework**:
   - Combines all checks into dashboard query
   - Suggests scheduling frequency based on update patterns
   - Provides implementation examples for different orchestration tools
   - Includes alert configuration recommendations

## Error Handling

- **Missing schema information**: Generates generic checks and recommends providing schema details for more specific validation
- **Invalid table reference**: Returns error with correct format example
- **Conflicting validation rules**: Highlights conflicts and suggests resolution
- **No validation types specified**: Defaults to all validation types with informational message
- **Inaccessible table**: Provides query to check table existence and permissions

## Use Cases

1. **New pipeline validation**: Implement quality gates for newly developed data pipelines
2. **Production monitoring**: Ongoing data quality monitoring for production tables
3. **Migration validation**: Validate data accuracy during platform migrations
4. **Compliance auditing**: Ensure data quality for regulatory compliance
5. **Anomaly detection**: Detect unexpected data patterns or quality degradation
6. **SLA monitoring**: Track adherence to data delivery service level agreements

## Examples

### Example 1: Customer Dimension Table Validation

**Input:**
```json
{
  "table_reference": "analytics.dwh.dim_customer",
  "validation_types": ["completeness", "uniqueness", "accuracy"],
  "schema_info": {
    "primary_keys": ["customer_id"],
    "required_fields": ["customer_id", "email", "registration_date"],
    "unique_fields": ["customer_id", "email"]
  },
  "business_rules": [
    {
      "field": "email",
      "rule_type": "format",
      "rule_spec": "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
    },
    {
      "field": "registration_date",
      "rule_type": "range",
      "rule_spec": "between 2020-01-01 and CURRENT_DATE"
    }
  ],
  "alert_thresholds": {
    "null_percentage_threshold": 2,
    "duplicate_threshold": 0
  }
}
```

**Output:**
```json
{
  "validation_suite": {
    "table": "analytics.dwh.dim_customer",
    "generated_at": "2025-01-15T14:30:00Z",
    "total_checks": 8
  },
  "completeness_checks": [
    {
      "check_name": "required_fields_null_check",
      "description": "Verify required fields have no null values",
      "sql_query": "SELECT\n  'customer_id' as field_name,\n  COUNTIF(customer_id IS NULL) as null_count,\n  COUNT(*) as total_count,\n  ROUND(SAFE_DIVIDE(COUNTIF(customer_id IS NULL), COUNT(*)) * 100, 2) as null_percentage\nFROM `analytics.dwh.dim_customer`\nUNION ALL\nSELECT\n  'email' as field_name,\n  COUNTIF(email IS NULL) as null_count,\n  COUNT(*) as total_count,\n  ROUND(SAFE_DIVIDE(COUNTIF(email IS NULL), COUNT(*)) * 100, 2) as null_percentage\nFROM `analytics.dwh.dim_customer`\nUNION ALL\nSELECT\n  'registration_date' as field_name,\n  COUNTIF(registration_date IS NULL) as null_count,\n  COUNT(*) as total_count,\n  ROUND(SAFE_DIVIDE(COUNTIF(registration_date IS NULL), COUNT(*)) * 100, 2) as null_percentage\nFROM `analytics.dwh.dim_customer`\nHAVING null_percentage > 2;",
      "pass_criteria": "null_percentage <= 2% for all required fields",
      "alert_on": "Any field with null_percentage > 2"
    },
    {
      "check_name": "row_count_validation",
      "description": "Ensure table has expected minimum row count",
      "sql_query": "SELECT\n  COUNT(*) as total_rows,\n  CASE\n    WHEN COUNT(*) = 0 THEN 'CRITICAL: Empty table'\n    WHEN COUNT(*) < 1000 THEN 'WARNING: Unexpectedly low row count'\n    ELSE 'OK'\n  END as status\nFROM `analytics.dwh.dim_customer`;",
      "pass_criteria": "Table contains rows",
      "alert_on": "total_rows = 0 or unexpectedly low"
    }
  ],
  "uniqueness_checks": [
    {
      "check_name": "primary_key_uniqueness",
      "description": "Validate customer_id is unique",
      "sql_query": "SELECT\n  customer_id,\n  COUNT(*) as duplicate_count\nFROM `analytics.dwh.dim_customer`\nGROUP BY customer_id\nHAVING COUNT(*) > 1\nORDER BY duplicate_count DESC;",
      "pass_criteria": "Zero duplicate customer_id values",
      "alert_on": "duplicate_count > 0"
    },
    {
      "check_name": "email_uniqueness",
      "description": "Validate email addresses are unique",
      "sql_query": "SELECT\n  email,\n  COUNT(*) as duplicate_count,\n  STRING_AGG(CAST(customer_id AS STRING), ', ' ORDER BY customer_id) as customer_ids\nFROM `analytics.dwh.dim_customer`\nWHERE email IS NOT NULL\nGROUP BY email\nHAVING COUNT(*) > 1\nORDER BY duplicate_count DESC;",
      "pass_criteria": "Zero duplicate email values",
      "alert_on": "duplicate_count > 0"
    }
  ],
  "accuracy_checks": [
    {
      "check_name": "email_format_validation",
      "description": "Validate email format using regex",
      "sql_query": "SELECT\n  customer_id,\n  email,\n  'Invalid email format' as issue\nFROM `analytics.dwh.dim_customer`\nWHERE email IS NOT NULL\n  AND NOT REGEXP_CONTAINS(email, r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$')\nLIMIT 100;",
      "pass_criteria": "All emails match valid format",
      "alert_on": "Any invalid email formats found"
    },
    {
      "check_name": "registration_date_range",
      "description": "Validate registration_date is within acceptable range",
      "sql_query": "SELECT\n  customer_id,\n  registration_date,\n  CASE\n    WHEN registration_date < '2020-01-01' THEN 'Before valid range'\n    WHEN registration_date > CURRENT_DATE() THEN 'Future date'\n    ELSE 'OK'\n  END as issue\nFROM `analytics.dwh.dim_customer`\nWHERE registration_date IS NOT NULL\n  AND (registration_date < '2020-01-01' OR registration_date > CURRENT_DATE())\nLIMIT 100;",
      "pass_criteria": "All registration dates between 2020-01-01 and today",
      "alert_on": "Any dates outside valid range"
    }
  ],
  "monitoring_dashboard_query": "-- Combined Data Quality Dashboard Query\nWITH quality_metrics AS (\n  SELECT\n    CURRENT_TIMESTAMP() as check_timestamp,\n    COUNT(*) as total_rows,\n    COUNTIF(customer_id IS NULL) as null_customer_ids,\n    COUNTIF(email IS NULL) as null_emails,\n    COUNTIF(registration_date IS NULL) as null_reg_dates,\n    COUNTIF(email IS NOT NULL AND NOT REGEXP_CONTAINS(email, r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$')) as invalid_emails,\n    COUNTIF(registration_date < '2020-01-01' OR registration_date > CURRENT_DATE()) as invalid_dates\n  FROM `analytics.dwh.dim_customer`\n),\nduplicate_metrics AS (\n  SELECT\n    COUNT(*) as duplicate_customer_id_count\n  FROM (\n    SELECT customer_id\n    FROM `analytics.dwh.dim_customer`\n    GROUP BY customer_id\n    HAVING COUNT(*) > 1\n  )\n)\nSELECT\n  qm.*,\n  dm.duplicate_customer_id_count,\n  ROUND(SAFE_DIVIDE(qm.null_customer_ids, qm.total_rows) * 100, 2) as null_customer_id_pct,\n  ROUND(SAFE_DIVIDE(qm.null_emails, qm.total_rows) * 100, 2) as null_email_pct,\n  ROUND(SAFE_DIVIDE(qm.invalid_emails, qm.total_rows) * 100, 2) as invalid_email_pct\nFROM quality_metrics qm\nCROSS JOIN duplicate_metrics dm;",
  "scheduled_check_framework": {
    "recommended_schedule": "Every 4 hours (dimension table, moderate update frequency)",
    "implementation_options": [
      "Dataform: Create assertions in definitions/quality_checks/dim_customer_checks.sqlx",
      "Airflow: Use BigQueryCheckOperator in DAG",
      "Cloud Scheduler: Trigger Cloud Function to run validation queries",
      "dbt: Implement as generic or custom data tests"
    ]
  },
  "alert_configuration": {
    "recommended_channels": ["email", "slack"],
    "severity_levels": {
      "critical": [
        "duplicate_customer_id_count > 0",
        "null_customer_id_pct > 0",
        "total_rows = 0"
      ],
      "warning": [
        "null_email_pct > 2",
        "invalid_email_pct > 1",
        "invalid_dates > 10"
      ],
      "info": [
        "Regular quality metrics summary"
      ]
    }
  }
}
```

### Example 2: Real-time Event Stream Timeliness Check

**Input:**
```json
{
  "table_reference": "streaming.events.user_events",
  "validation_types": ["timeliness", "completeness"],
  "sla_requirements": {
    "max_age_hours": 1,
    "min_row_count": 10000,
    "update_frequency": "continuous"
  },
  "alert_thresholds": {
    "freshness_threshold_hours": 1
  },
  "monitoring_period": "1 hour"
}
```

**Output:**
```json
{
  "validation_suite": {
    "table": "streaming.events.user_events",
    "generated_at": "2025-01-15T14:30:00Z",
    "total_checks": 3
  },
  "completeness_checks": [
    {
      "check_name": "hourly_volume_check",
      "description": "Verify minimum event volume in last hour",
      "sql_query": "SELECT\n  COUNT(*) as events_last_hour,\n  CASE\n    WHEN COUNT(*) < 10000 THEN 'CRITICAL: Below minimum threshold'\n    WHEN COUNT(*) < 50000 THEN 'WARNING: Lower than expected'\n    ELSE 'OK'\n  END as status\nFROM `streaming.events.user_events`\nWHERE event_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR);",
      "pass_criteria": "At least 10,000 events in last hour",
      "alert_on": "events_last_hour < 10000"
    }
  ],
  "timeliness_checks": [
    {
      "check_name": "streaming_freshness",
      "description": "Monitor time since last event ingestion",
      "sql_query": "SELECT\n  MAX(event_timestamp) as latest_event,\n  CURRENT_TIMESTAMP() as check_time,\n  TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), MAX(event_timestamp), MINUTE) as minutes_since_last_event,\n  CASE\n    WHEN TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), MAX(event_timestamp), MINUTE) > 60 THEN 'CRITICAL: Data pipeline may be down'\n    WHEN TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), MAX(event_timestamp), MINUTE) > 15 THEN 'WARNING: Lag detected'\n    ELSE 'OK'\n  END as status\nFROM `streaming.events.user_events`;",
      "pass_criteria": "Latest event within last 60 minutes",
      "alert_on": "minutes_since_last_event > 60"
    },
    {
      "check_name": "partition_completeness",
      "description": "Verify all hourly partitions exist for last 24 hours",
      "sql_query": "WITH expected_hours AS (\n  SELECT hour\n  FROM UNNEST(GENERATE_TIMESTAMP_ARRAY(\n    TIMESTAMP_TRUNC(TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR), HOUR),\n    TIMESTAMP_TRUNC(CURRENT_TIMESTAMP(), HOUR),\n    INTERVAL 1 HOUR\n  )) AS hour\n),\nactual_hours AS (\n  SELECT\n    TIMESTAMP_TRUNC(event_timestamp, HOUR) as hour,\n    COUNT(*) as event_count\n  FROM `streaming.events.user_events`\n  WHERE event_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)\n  GROUP BY 1\n)\nSELECT\n  e.hour as expected_hour,\n  COALESCE(a.event_count, 0) as event_count,\n  CASE\n    WHEN a.event_count IS NULL THEN 'CRITICAL: Missing partition'\n    WHEN a.event_count < 1000 THEN 'WARNING: Low volume'\n    ELSE 'OK'\n  END as status\nFROM expected_hours e\nLEFT JOIN actual_hours a ON e.hour = a.hour\nWHERE a.event_count IS NULL OR a.event_count < 1000\nORDER BY e.hour DESC;",
      "pass_criteria": "All hourly partitions present with adequate volume",
      "alert_on": "Any missing partitions or low-volume hours"
    }
  ],
  "monitoring_dashboard_query": "-- Streaming Data Quality Dashboard\nSELECT\n  CURRENT_TIMESTAMP() as check_time,\n  MAX(event_timestamp) as latest_event,\n  TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), MAX(event_timestamp), MINUTE) as lag_minutes,\n  COUNT(*) as total_events,\n  COUNT(DISTINCT DATE(event_timestamp)) as days_covered,\n  COUNTIF(event_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR)) as last_hour_events,\n  COUNTIF(event_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 5 MINUTE)) as last_5min_events,\n  ROUND(COUNTIF(event_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 5 MINUTE)) / 5, 2) as events_per_minute\nFROM `streaming.events.user_events`\nWHERE event_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR);",
  "scheduled_check_framework": {
    "recommended_schedule": "Every 5 minutes (real-time streaming data)",
    "implementation_options": [
      "Cloud Scheduler: High-frequency checks via Cloud Functions",
      "Cloud Monitoring: Custom metrics and alerting policies",
      "Airflow Sensor: Continuous monitoring with short poke intervals",
      "Dataflow metrics: Monitor pipeline lag and throughput directly"
    ]
  },
  "alert_configuration": {
    "recommended_channels": ["pagerduty", "slack"],
    "severity_levels": {
      "critical": [
        "lag_minutes > 60 (pipeline down)",
        "last_hour_events < 10000 (volume too low)",
        "Missing hourly partitions"
      ],
      "warning": [
        "lag_minutes > 15 (elevated lag)",
        "last_hour_events < 50000 (lower than normal)",
        "events_per_minute < 100"
      ],
      "info": [
        "Hourly summary of streaming metrics"
      ]
    }
  }
}
```

## Constraints

- Validation queries should be efficient and not cause performance issues on production tables
- For large tables (>100M rows), use sampling or partition filtering where appropriate
- Freshness checks require a timestamp column (event_timestamp, updated_at, etc.)
- Referential integrity checks can be expensive; consider scheduling during off-peak hours
- Alert thresholds should be calibrated based on actual data characteristics
- Validation frequency should match data update patterns (real-time vs. batch)

## Success Criteria

- [ ] All requested validation types have corresponding SQL queries
- [ ] Queries are optimized with appropriate filtering and sampling
- [ ] Pass criteria are clearly defined and measurable
- [ ] Alert conditions are specific and actionable
- [ ] Dashboard query combines all metrics efficiently
- [ ] Scheduling recommendations match data update patterns
- [ ] Severity levels appropriately categorize different failure scenarios
- [ ] Queries follow BigQuery best practices (partition pruning, etc.)
- [ ] Examples are provided for implementation in common orchestration tools
- [ ] SQL queries are syntactically valid and executable

## Dependencies

- Table must exist and be accessible with current credentials
- Schema information improves check quality (primary keys, required fields)
- Timestamp columns required for timeliness checks
- Understanding of expected data volumes and update patterns
- Knowledge of business rules and acceptable quality thresholds

## Composition Notes

This skill combines well with:
- **bigquery-schema-design**: Design schemas with quality validation in mind
- **gcp-pipeline-architecture**: Integrate quality checks into pipeline workflows
- **bigquery-query-optimization**: Ensure validation queries are performant
- **etl-pattern-selection**: Choose patterns that facilitate quality validation

Use validation output to:
- Configure monitoring dashboards in Looker or Data Studio
- Implement Dataform or dbt test assertions
- Set up Cloud Monitoring alerting policies
- Create Airflow data quality operators
- Build automated data quality reports
