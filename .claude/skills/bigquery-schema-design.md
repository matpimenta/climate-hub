---
name: bigquery-schema-design
description: "Design optimal BigQuery table schemas with appropriate partitioning, clustering, and data types for analytical workloads"
---

# BigQuery Schema Design - Analytical Data Warehouse Optimization

## Purpose
This skill provides expert guidance on designing BigQuery table schemas optimized for analytical workloads, including selecting appropriate data types, implementing partitioning and clustering strategies, and structuring tables for optimal performance and cost efficiency.

## Input Parameters

**Required:**
- `table_purpose` (string): Description of the table's purpose and use case (e.g., "fact table for sales transactions", "customer dimension table", "event streaming data")
- `expected_query_patterns` (array): List of common query patterns that will access this table (e.g., ["filter by date range", "group by customer and product", "join with dimension tables"])
- `data_volume` (object): Expected data characteristics
  - `row_count` (number): Approximate number of rows
  - `growth_rate` (string): Data growth pattern (e.g., "1M rows/day", "static", "5% monthly growth")
  - `retention_period` (string): How long data should be retained (e.g., "7 years", "90 days", "indefinite")

**Optional:**
- `sample_fields` (array): Example fields with sample data to help determine types
- `nested_structures` (boolean): Whether the data contains nested objects or arrays (default: false)
- `compliance_requirements` (array): Any security/compliance needs (e.g., ["PII", "GDPR", "column-level encryption"])
- `cost_priority` (string): Balance between cost and performance ("cost-optimized", "balanced", "performance-optimized", default: "balanced")

## Output Format

```json
{
  "schema_definition": {
    "table_name": "string",
    "table_type": "standard|partitioned|clustered|external",
    "fields": [
      {
        "name": "field_name",
        "type": "INT64|STRING|TIMESTAMP|DATE|STRUCT|ARRAY|etc",
        "mode": "REQUIRED|NULLABLE|REPEATED",
        "description": "Field purpose and usage",
        "policy_tag": "optional security tag"
      }
    ]
  },
  "partitioning_strategy": {
    "enabled": true|false,
    "type": "time-unit|integer-range|ingestion-time",
    "column": "partition_column_name",
    "granularity": "hour|day|month|year",
    "expiration_days": 2555,
    "require_partition_filter": true|false,
    "rationale": "Why this partitioning approach"
  },
  "clustering_strategy": {
    "enabled": true|false,
    "columns": ["column1", "column2", "column3", "column4"],
    "column_order_rationale": "Why columns are ordered this way",
    "expected_pruning_benefit": "percentage or description"
  },
  "create_table_sql": "Complete CREATE TABLE statement",
  "performance_recommendations": [
    "Specific recommendations for query optimization"
  ],
  "cost_estimates": {
    "storage_considerations": "Description of storage costs",
    "query_cost_factors": "What will affect query costs",
    "optimization_opportunities": ["List of cost-saving recommendations"]
  },
  "security_recommendations": [
    "IAM roles needed",
    "Column-level security suggestions",
    "Row-level security if applicable"
  ]
}
```

## Behavior

This skill analyzes the provided requirements and produces a comprehensive schema design following these steps:

1. **Data Type Selection**: Chooses optimal BigQuery data types based on:
   - Data characteristics and sample values
   - Storage efficiency (INT64 vs STRING for IDs, DATE vs TIMESTAMP)
   - Query performance implications
   - Support for nested structures (STRUCT, ARRAY) when appropriate

2. **Partitioning Analysis**: Determines if partitioning is beneficial based on:
   - Table size (recommends for tables >1GB)
   - Query patterns (time-based filtering, range queries)
   - Data retention requirements
   - Cost optimization opportunities
   - Partition count limitations (<4,000 partitions)

3. **Clustering Design**: Selects clustering columns based on:
   - High-cardinality columns used in WHERE clauses
   - Columns used in JOIN conditions
   - ORDER BY column usage frequency
   - Optimal ordering (most filtered columns first)
   - Maximum of 4 clustering columns

4. **Table Type Determination**: Chooses between:
   - Standard tables for small or static datasets
   - Partitioned tables for large time-series data
   - Clustered tables for high-cardinality filter columns
   - External tables for data lake queries
   - Combination strategies (partitioned + clustered)

5. **Schema Validation**: Ensures the design follows best practices:
   - Required fields are marked as REQUIRED (not nullable)
   - Appropriate use of STRUCT for nested objects
   - ARRAY for repeated values
   - No excessively wide schemas (>10,000 columns warning)
   - Proper description documentation

## Error Handling

- **Insufficient query pattern information**: Returns request for more specific query patterns with examples
- **Conflicting requirements**: Highlights conflicts (e.g., "require low cost but need millisecond query performance") and suggests tradeoffs
- **Invalid partition strategy**: Warns if partition count would exceed limits or if partition column is inappropriate
- **Missing critical information**: Requests specific data volume or retention information if not provided

## Use Cases

1. **New data warehouse table design**: Starting fresh with a fact or dimension table
2. **Schema migration from another platform**: Converting from Redshift, Snowflake, or traditional RDBMS
3. **Performance optimization**: Redesigning existing tables for better query performance
4. **Cost reduction**: Restructuring tables to minimize query and storage costs
5. **Real-time streaming tables**: Designing tables optimized for high-throughput streaming inserts

## Examples

### Example 1: E-commerce Sales Fact Table

**Input:**
```json
{
  "table_purpose": "Fact table storing all sales transactions for e-commerce platform",
  "expected_query_patterns": [
    "Daily sales reports filtered by date range",
    "Customer purchase history (filter by customer_id)",
    "Product performance analysis (group by product_id)",
    "Regional sales (filter by region, join with dimension tables)"
  ],
  "data_volume": {
    "row_count": 500000000,
    "growth_rate": "2M rows/day",
    "retention_period": "7 years"
  },
  "nested_structures": false,
  "cost_priority": "balanced"
}
```

**Output:**
```json
{
  "schema_definition": {
    "table_name": "fact_sales",
    "table_type": "partitioned_clustered",
    "fields": [
      {"name": "sale_id", "type": "INT64", "mode": "REQUIRED", "description": "Unique sale identifier"},
      {"name": "sale_timestamp", "type": "TIMESTAMP", "mode": "REQUIRED", "description": "Transaction timestamp"},
      {"name": "sale_date", "type": "DATE", "mode": "REQUIRED", "description": "Transaction date (partition column)"},
      {"name": "customer_id", "type": "INT64", "mode": "REQUIRED", "description": "Customer identifier"},
      {"name": "product_id", "type": "INT64", "mode": "REQUIRED", "description": "Product identifier"},
      {"name": "quantity", "type": "INT64", "mode": "REQUIRED", "description": "Quantity sold"},
      {"name": "unit_price", "type": "NUMERIC", "mode": "REQUIRED", "description": "Price per unit"},
      {"name": "total_amount", "type": "NUMERIC", "mode": "REQUIRED", "description": "Total transaction amount"},
      {"name": "region", "type": "STRING", "mode": "REQUIRED", "description": "Sales region"}
    ]
  },
  "partitioning_strategy": {
    "enabled": true,
    "type": "time-unit",
    "column": "sale_date",
    "granularity": "day",
    "expiration_days": 2555,
    "require_partition_filter": true,
    "rationale": "Daily partitioning enables efficient date range queries and automatic partition expiration after 7 years. Require_partition_filter prevents expensive full table scans."
  },
  "clustering_strategy": {
    "enabled": true,
    "columns": ["customer_id", "product_id", "region"],
    "column_order_rationale": "customer_id first (customer history queries), product_id second (product analysis), region third (regional filtering). Ordered by query frequency.",
    "expected_pruning_benefit": "60-80% reduction in data scanned for customer and product queries"
  },
  "create_table_sql": "CREATE OR REPLACE TABLE `project.dataset.fact_sales` (\n  sale_id INT64 NOT NULL,\n  sale_timestamp TIMESTAMP NOT NULL,\n  sale_date DATE NOT NULL,\n  customer_id INT64 NOT NULL,\n  product_id INT64 NOT NULL,\n  quantity INT64 NOT NULL,\n  unit_price NUMERIC(10,2) NOT NULL,\n  total_amount NUMERIC(10,2) NOT NULL,\n  region STRING NOT NULL\n)\nPARTITION BY sale_date\nCLUSTER BY customer_id, product_id, region\nOPTIONS(\n  description='Sales fact table with daily partitions',\n  require_partition_filter=TRUE,\n  partition_expiration_days=2555\n);",
  "performance_recommendations": [
    "Always include sale_date in WHERE clause to leverage partitioning",
    "Filter by customer_id, product_id, or region to benefit from clustering",
    "Use CURRENT_DATE() - INTERVAL for rolling date windows",
    "Consider materialized views for frequently-run aggregation queries"
  ],
  "cost_estimates": {
    "storage_considerations": "~50GB/year with 2M rows/day. Long-term storage discount after 90 days reduces costs by 50%.",
    "query_cost_factors": "Partitioning reduces date-filtered queries by 95%+. Clustering reduces customer/product queries by 60-80%.",
    "optimization_opportunities": [
      "Set partition expiration to automatically delete old data",
      "Use BI Engine for frequently accessed recent data",
      "Implement aggregation tables for common dashboard queries"
    ]
  },
  "security_recommendations": [
    "Grant roles/bigquery.dataViewer for read-only analysts",
    "Grant roles/bigquery.dataEditor for ETL processes",
    "No PII detected, standard IAM sufficient",
    "Enable audit logging for compliance"
  ]
}
```

### Example 2: Streaming Event Table with Nested Data

**Input:**
```json
{
  "table_purpose": "Real-time user event tracking for web analytics",
  "expected_query_patterns": [
    "Recent events by user (last 24 hours)",
    "Event type analysis by hour",
    "Session reconstruction (filter by session_id)",
    "Extract specific properties from nested event data"
  ],
  "data_volume": {
    "row_count": 10000000000,
    "growth_rate": "10M rows/day",
    "retention_period": "90 days"
  },
  "sample_fields": [
    {"event_timestamp": "2025-01-15T10:30:45Z", "user_id": "usr_12345", "event_type": "page_view", "properties": {"page": "/products", "referrer": "google"}}
  ],
  "nested_structures": true,
  "cost_priority": "cost-optimized"
}
```

**Output:**
```json
{
  "schema_definition": {
    "table_name": "events_streaming",
    "table_type": "partitioned_clustered",
    "fields": [
      {"name": "event_id", "type": "STRING", "mode": "REQUIRED", "description": "Unique event identifier"},
      {"name": "event_timestamp", "type": "TIMESTAMP", "mode": "REQUIRED", "description": "Event occurrence time"},
      {"name": "user_id", "type": "STRING", "mode": "REQUIRED", "description": "User identifier"},
      {"name": "session_id", "type": "STRING", "mode": "NULLABLE", "description": "Session identifier"},
      {"name": "event_type", "type": "STRING", "mode": "REQUIRED", "description": "Type of event"},
      {
        "name": "properties",
        "type": "RECORD",
        "mode": "NULLABLE",
        "description": "Event properties as nested structure",
        "fields": [
          {"name": "page", "type": "STRING", "mode": "NULLABLE"},
          {"name": "referrer", "type": "STRING", "mode": "NULLABLE"}
        ]
      }
    ]
  },
  "partitioning_strategy": {
    "enabled": true,
    "type": "time-unit",
    "column": "event_timestamp",
    "granularity": "hour",
    "expiration_days": 90,
    "require_partition_filter": true,
    "rationale": "Hourly partitions for recent event queries. 90-day expiration matches retention policy and automatically manages costs. Cost-optimized approach."
  },
  "clustering_strategy": {
    "enabled": true,
    "columns": ["user_id", "event_type"],
    "column_order_rationale": "user_id first for user-centric queries, event_type second for event analysis. Only 2 columns to minimize clustering overhead for streaming inserts.",
    "expected_pruning_benefit": "70% reduction for user-specific queries"
  },
  "create_table_sql": "CREATE OR REPLACE TABLE `project.dataset.events_streaming` (\n  event_id STRING NOT NULL,\n  event_timestamp TIMESTAMP NOT NULL,\n  user_id STRING NOT NULL,\n  session_id STRING,\n  event_type STRING NOT NULL,\n  properties STRUCT<\n    page STRING,\n    referrer STRING\n  >\n)\nPARTITION BY TIMESTAMP_TRUNC(event_timestamp, HOUR)\nCLUSTER BY user_id, event_type\nOPTIONS(\n  description='Real-time event streaming table',\n  require_partition_filter=TRUE,\n  partition_expiration_days=90\n);",
  "performance_recommendations": [
    "Use Storage Write API for high-throughput streaming (>100k rows/sec)",
    "Always filter by event_timestamp with specific time ranges",
    "Use UNNEST for querying nested properties fields",
    "Consider separate aggregation tables for dashboard queries",
    "Implement dead letter queue for malformed events"
  ],
  "cost_estimates": {
    "storage_considerations": "~2.7TB total with 90-day retention. Automatic expiration prevents unbounded growth.",
    "query_cost_factors": "Hourly partitioning + clustering dramatically reduces costs for recent time window queries (95%+ reduction).",
    "optimization_opportunities": [
      "Partition expiration eliminates manual deletion costs",
      "Use approximate aggregations (APPROX_COUNT_DISTINCT) for large datasets",
      "Leverage streaming buffer for real-time dashboards",
      "Consider exporting cold data to Cloud Storage for archival"
    ]
  },
  "security_recommendations": [
    "Implement column-level security if properties contain PII",
    "Use authorized views to restrict sensitive event types",
    "Monitor streaming insert quotas and errors",
    "Enable audit logging for compliance tracking"
  ]
}
```

## Constraints

- Maximum 4 clustering columns per table
- Maximum 4,000 partitions per table (enforce through expiration)
- Schema width should not exceed 10,000 columns (warn at 1,000+)
- Partition column must be of type DATE, TIMESTAMP, or INTEGER (for range partitioning)
- Clustering columns should be high-cardinality for effectiveness
- Nested STRUCT depth should be reasonable (<5 levels) for query performance
- Field names must follow BigQuery naming conventions (letters, numbers, underscores)
- Partition expiration should align with retention requirements

## Success Criteria

- [ ] All required fields are explicitly marked as REQUIRED (mode)
- [ ] Partitioning strategy matches query patterns and data volume
- [ ] Clustering columns ordered by filter frequency
- [ ] Data types are storage and performance optimal
- [ ] CREATE TABLE SQL is valid and executable
- [ ] Partition count stays under 4,000 limit
- [ ] Cost optimization recommendations are specific and actionable
- [ ] Security considerations address compliance requirements
- [ ] Schema supports all specified query patterns efficiently
- [ ] Documentation includes clear rationale for all design decisions

## Dependencies

- Understanding of BigQuery data types and their storage implications
- Knowledge of query execution plans and partition/cluster pruning
- Familiarity with GCP IAM roles and BigQuery security features
- Understanding of cost factors (storage, query processing, streaming inserts)

## Composition Notes

This skill can be combined with:
- **bigquery-query-optimization**: Use schema design to inform query optimization strategies
- **data-quality-validation**: Implement validation checks that align with schema constraints
- **gcp-pipeline-architecture**: Design schemas that fit into broader data pipeline architecture
- **etl-pattern-selection**: Choose schemas optimized for selected ETL/ELT patterns

The schema design output provides a foundation for subsequent pipeline development, query optimization, and data governance implementation.
