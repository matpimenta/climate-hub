---
name: gcp-pipeline-architecture
description: "Select and design optimal GCP data pipeline architecture using appropriate services for ETL, ELT, streaming, and batch processing workflows"
---

# GCP Data Pipeline Architecture - Service Selection and Design

## Purpose
This skill provides expert guidance on selecting the optimal combination of GCP services for data pipeline architecture based on data characteristics, processing requirements, latency needs, and cost constraints. It produces architectural recommendations, service configurations, and implementation guidance for building scalable data pipelines on Google Cloud Platform.

## Input Parameters

**Required:**
- `pipeline_purpose` (string): High-level description of what the pipeline should accomplish
- `data_sources` (array): List of data sources with characteristics
  - Each source: `{"type": "database|api|file|stream|pubsub", "volume": "size/frequency", "format": "json|csv|parquet|avro|proto"}`
- `data_destination` (string): Primary destination ("BigQuery", "Cloud Storage", "Bigtable", "Firestore", etc.)
- `processing_requirements` (array): What needs to happen to the data
  - Options: "filtering", "transformation", "enrichment", "aggregation", "deduplication", "validation", "ML inference"

**Optional:**
- `latency_requirement` (string): Acceptable end-to-end latency
  - Options: "real-time" (<1 min), "near-real-time" (1-15 min), "batch-hourly", "batch-daily", "batch-weekly"
- `data_volume` (object): Expected data characteristics
  - `records_per_day` (number): Daily record count
  - `avg_record_size_kb` (number): Average record size
  - `peak_throughput` (string): Peak processing rate (e.g., "10k records/sec")
- `cost_priority` (string): Cost vs performance tradeoff
  - Options: "cost-optimized", "balanced", "performance-optimized" (default: "balanced")
- `complexity_factors` (array): Special requirements
  - Options: "exactly-once semantics", "schema evolution", "late data handling", "data quality checks", "compliance logging", "multi-region"
- `existing_infrastructure` (array): Services already in use (for integration)
- `team_expertise` (array): Team's familiarity with GCP services

## Output Format

```json
{
  "architecture_summary": {
    "pipeline_type": "batch|streaming|hybrid|event-driven",
    "primary_services": ["Dataflow", "BigQuery", "Cloud Storage"],
    "complexity_level": "simple|moderate|complex",
    "estimated_monthly_cost": "$X,XXX - $Y,YYY range",
    "implementation_effort": "person-weeks estimate"
  },
  "recommended_architecture": {
    "ingestion_layer": {
      "services": ["Pub/Sub", "Cloud Storage"],
      "rationale": "Why these services",
      "configuration": {
        "service_name": {
          "key_settings": "specific configurations",
          "scaling_strategy": "how to handle growth"
        }
      }
    },
    "processing_layer": {
      "services": ["Dataflow", "BigQuery scheduled queries"],
      "rationale": "Processing approach justification",
      "configuration": {}
    },
    "storage_layer": {
      "services": ["BigQuery", "Cloud Storage"],
      "rationale": "Storage strategy",
      "configuration": {}
    },
    "orchestration": {
      "service": "Cloud Composer|Cloud Scheduler|Workflows",
      "rationale": "Why this orchestration approach",
      "configuration": {}
    },
    "monitoring": {
      "services": ["Cloud Monitoring", "Cloud Logging", "Error Reporting"],
      "key_metrics": ["List of important metrics to track"],
      "alerting_strategy": "When and how to alert"
    }
  },
  "architecture_diagram": "ASCII or textual representation of data flow",
  "alternative_architectures": [
    {
      "approach": "Alternative approach description",
      "trade_offs": "Pros and cons vs recommended",
      "use_case": "When to use this instead"
    }
  ],
  "implementation_phases": [
    {
      "phase": 1,
      "name": "MVP/Prototype",
      "components": ["Initial services to implement"],
      "success_criteria": ["What to validate"],
      "estimated_duration": "time estimate"
    }
  ],
  "cost_breakdown": {
    "ingestion": "Cost estimate and factors",
    "processing": "Cost estimate and factors",
    "storage": "Cost estimate and factors",
    "optimization_tips": ["Ways to reduce costs"]
  },
  "scalability_considerations": {
    "bottlenecks": ["Potential scaling challenges"],
    "scaling_strategy": ["How to scale each component"],
    "capacity_planning": "Guidelines for growth"
  },
  "security_recommendations": {
    "iam_roles": ["Required IAM roles and service accounts"],
    "network": "VPC, private endpoints, etc.",
    "encryption": "Encryption at rest and in transit",
    "compliance": "Relevant compliance considerations"
  },
  "example_implementation": "Code snippet or configuration example for key component"
}
```

## Behavior

This skill analyzes requirements and produces architecture recommendations through:

1. **Pipeline Pattern Identification**:
   - **Batch Processing**: Daily/hourly data loads with Cloud Storage + BigQuery or Dataflow
   - **Streaming**: Real-time ingestion with Pub/Sub + Dataflow + BigQuery
   - **Event-Driven**: Triggered processing with Cloud Functions or Eventarc
   - **Hybrid**: Combination of streaming and batch components
   - **Micro-batch**: Near-real-time with small batch windows

2. **Service Selection Logic**:
   - **Ingestion**:
     - Pub/Sub: Real-time events, decoupling sources, fan-out patterns
     - Cloud Storage: Batch file landing zone, data lake raw storage
     - Data Transfer Service: Managed transfers from external sources (S3, databases)
     - API Gateway + Cloud Functions: Custom API ingestion

   - **Processing**:
     - Dataflow: Complex transformations, streaming windowing, Apache Beam pipelines
     - BigQuery: SQL-based transformations, ELT patterns, built-in ML
     - Dataproc: Spark/Hadoop workloads, existing Spark code
     - Cloud Functions: Lightweight event processing, simple transformations
     - Dataform: SQL-based transformation workflows with dependency management

   - **Orchestration**:
     - Cloud Composer (Airflow): Complex DAGs, many dependencies, robust scheduling
     - Cloud Scheduler: Simple scheduled triggers for Cloud Functions/Dataflow
     - Workflows: Event-driven orchestration, serverless, simple sequences
     - Eventarc: Event-driven architecture, Cloud Events integration

   - **Storage**:
     - BigQuery: Data warehouse, SQL analytics, BI dashboards
     - Cloud Storage: Data lake, unstructured data, archival
     - Bigtable: High-throughput reads/writes, time-series data
     - Firestore: Document store, real-time sync, mobile/web apps

3. **Architecture Optimization**:
   - Cost optimization: Choose serverless where possible, right-size resources
   - Performance: Minimize data movement, parallel processing, appropriate caching
   - Reliability: Implement retries, dead letter queues, idempotency
   - Maintainability: Use managed services, infrastructure as code, monitoring

4. **Latency-Based Decisions**:
   - Real-time (<1 min): Pub/Sub → Dataflow Streaming → BigQuery Storage Write API
   - Near-real-time (1-15 min): Pub/Sub → Dataflow with micro-batches
   - Hourly batch: Cloud Scheduler → Dataflow or BigQuery scheduled queries
   - Daily batch: Cloud Composer DAG with BigQuery or Dataflow jobs

5. **Complexity Assessment**:
   - Simple: Single source → transformation → BigQuery (Cloud Functions or Scheduled Query)
   - Moderate: Multiple sources → Dataflow → BigQuery with orchestration
   - Complex: Multi-stage pipeline, multiple destinations, real-time + batch, advanced windowing

## Error Handling

- **Unclear requirements**: Asks clarifying questions about specific aspects (latency, volume, transformations)
- **Conflicting constraints**: Highlights impossible combinations (e.g., "real-time + cost-optimized + complex transformations on huge volumes")
- **Missing volume data**: Provides ranges or asks for ballpark estimates to inform recommendations
- **Unsupported source/destination**: Suggests alternative approaches or custom integration patterns

## Use Cases

1. **Building net-new data pipeline**: Architecture from scratch for new use case
2. **Migration from on-premises**: Moving existing ETL to GCP
3. **Modernization**: Replacing legacy batch processes with streaming or ELT
4. **Multi-cloud integration**: Ingesting data from AWS, Azure, or on-premises
5. **Real-time analytics**: Building streaming analytics pipelines
6. **ML feature engineering**: Pipelines for ML feature preparation and serving

## Examples

### Example 1: E-commerce Real-time Analytics Pipeline

**Input:**
```json
{
  "pipeline_purpose": "Real-time analytics dashboard for e-commerce platform showing current sales, inventory, and customer behavior",
  "data_sources": [
    {"type": "stream", "volume": "50k events/hour peak", "format": "json"},
    {"type": "database", "volume": "product catalog, updated hourly", "format": "mysql"}
  ],
  "data_destination": "BigQuery",
  "processing_requirements": ["filtering", "enrichment", "aggregation", "validation"],
  "latency_requirement": "near-real-time",
  "data_volume": {
    "records_per_day": 800000,
    "avg_record_size_kb": 2,
    "peak_throughput": "15k records/sec during flash sales"
  },
  "cost_priority": "balanced",
  "complexity_factors": ["late data handling", "data quality checks", "schema evolution"]
}
```

**Output:**
```json
{
  "architecture_summary": {
    "pipeline_type": "streaming with batch enrichment",
    "primary_services": ["Pub/Sub", "Dataflow", "BigQuery", "Cloud Storage"],
    "complexity_level": "moderate",
    "estimated_monthly_cost": "$1,500 - $3,000 (based on volume, scales with usage)",
    "implementation_effort": "4-6 person-weeks including testing"
  },
  "recommended_architecture": {
    "ingestion_layer": {
      "services": ["Pub/Sub"],
      "rationale": "Pub/Sub handles streaming event ingestion with automatic scaling to 15k/sec peaks, provides at-least-once delivery guarantees, and decouples event producers from processing pipeline",
      "configuration": {
        "pubsub_topic": {
          "message_retention": "7 days for replay capability",
          "schema_validation": "Enable schema validation for data quality",
          "dead_letter_topic": "Create DLQ for malformed messages",
          "ack_deadline": "600 seconds for complex processing"
        }
      }
    },
    "processing_layer": {
      "services": ["Dataflow Streaming", "BigQuery Scheduled Queries"],
      "rationale": "Dataflow streaming handles real-time event processing with windowing for aggregations, enrichment with product catalog data, and handles late-arriving data. BigQuery scheduled queries perform hourly product catalog sync from MySQL.",
      "configuration": {
        "dataflow_streaming": {
          "pipeline_type": "Apache Beam Python/Java",
          "windowing": "Fixed 5-minute windows with 10-minute allowed lateness",
          "autoscaling": "1-20 workers based on Pub/Sub backlog",
          "side_input": "Product catalog loaded periodically from BigQuery for enrichment",
          "output": "BigQuery Storage Write API for high-throughput",
          "worker_machine_type": "n1-standard-4 (balanced cost/performance)",
          "streaming_engine": "Enable for reduced worker resource usage"
        },
        "bigquery_scheduled_query": {
          "schedule": "Hourly at :00",
          "query": "MERGE pattern to sync product catalog from external MySQL table",
          "external_connection": "Cloud SQL proxy or federated query"
        }
      }
    },
    "storage_layer": {
      "services": ["BigQuery", "Cloud Storage"],
      "rationale": "BigQuery serves as data warehouse for analytics with partitioned/clustered tables for query performance. Cloud Storage archives raw events for reprocessing and compliance.",
      "configuration": {
        "bigquery": {
          "datasets": {
            "raw_events": "Landing zone for streaming inserts",
            "analytics": "Transformed tables for BI dashboards",
            "reference": "Product catalog and dimension tables"
          },
          "tables": {
            "raw_events.events": "Partitioned by event_timestamp (hour), clustered by user_id, event_type",
            "analytics.sales_metrics": "Materialized view for dashboard performance"
          }
        },
        "cloud_storage": {
          "bucket_structure": "gs://bucket/raw_events/YYYY/MM/DD/HH/*.json",
          "lifecycle_policy": "Move to Nearline after 30 days, Archive after 180 days",
          "archival_trigger": "Dataflow writes to GCS in addition to BigQuery"
        }
      }
    },
    "orchestration": {
      "service": "Cloud Scheduler + Cloud Monitoring",
      "rationale": "Lightweight orchestration sufficient for this pipeline. Dataflow streaming runs continuously, only hourly catalog sync needs scheduling. Cloud Monitoring handles alerting.",
      "configuration": {
        "cloud_scheduler": {
          "catalog_sync_job": "Triggers BigQuery scheduled query hourly",
          "health_check": "Every 5 minutes, verify Dataflow pipeline status"
        }
      }
    },
    "monitoring": {
      "services": ["Cloud Monitoring", "Cloud Logging", "Dataflow Monitoring"],
      "key_metrics": [
        "Pub/Sub: Subscription backlog, age of oldest unacked message",
        "Dataflow: System lag, data watermark lag, throughput",
        "BigQuery: Streaming insert errors, table row counts, query performance",
        "Custom: Data quality check failures, late data count"
      ],
      "alerting_strategy": "Critical alerts (PagerDuty): Pipeline down, backlog >30 min. Warning alerts (Slack): Elevated lag, data quality issues, unusual traffic patterns"
    }
  },
  "architecture_diagram": "Event Sources (Web, Mobile, APIs)\n      |\n      v\n  Pub/Sub Topic (streaming-events)\n      |\n      +---> Dataflow Streaming Pipeline\n      |       |\n      |       +---> Enrichment (join with product catalog from BigQuery)\n      |       +---> Windowing (5-min windows)\n      |       +---> Validation (data quality checks)\n      |       |\n      |       +---> BigQuery (raw_events.events) [Storage Write API]\n      |       +---> Cloud Storage (archive) [Avro files]\n      |\n      v\n  Pub/Sub DLQ (failed messages)\n\nMySQL (Product Catalog)\n      |\n      v\n  BigQuery Scheduled Query (hourly)\n      |\n      v\n  BigQuery (reference.products)\n\nBigQuery Analytics Layer\n  - Materialized Views\n  - Pre-aggregated tables\n      |\n      v\n  Looker / Data Studio Dashboards",
  "alternative_architectures": [
    {
      "approach": "BigQuery Streaming Inserts (direct from application)",
      "trade_offs": "Pros: Simpler, no Dataflow needed. Cons: No complex transformations, enrichment, or windowing. Limited error handling. Higher cost per insert.",
      "use_case": "Use if transformations are minimal and can be done in application layer before sending to BigQuery"
    },
    {
      "approach": "Cloud Functions for processing",
      "trade_offs": "Pros: Serverless, pay-per-invocation, simpler for basic transformations. Cons: 9-minute timeout limit, harder to manage state, not ideal for windowing or exactly-once semantics.",
      "use_case": "Use if processing is very simple (e.g., just filtering and reformatting) and volume is moderate (<1k/sec sustained)"
    }
  ],
  "implementation_phases": [
    {
      "phase": 1,
      "name": "MVP - Basic Streaming",
      "components": [
        "Pub/Sub topic and subscription",
        "Simple Dataflow pipeline (no enrichment, basic filtering)",
        "BigQuery raw events table",
        "Basic monitoring"
      ],
      "success_criteria": [
        "Events flowing end-to-end in <5 minutes",
        "No data loss during normal operations",
        "Basic dashboard showing event counts"
      ],
      "estimated_duration": "2 weeks"
    },
    {
      "phase": 2,
      "name": "Add Enrichment and Quality",
      "components": [
        "Product catalog sync from MySQL",
        "Dataflow enrichment logic with side inputs",
        "Data quality validation checks",
        "Dead letter queue handling"
      ],
      "success_criteria": [
        "Events enriched with product data",
        "Invalid events routed to DLQ",
        "Data quality metrics tracked"
      ],
      "estimated_duration": "2 weeks"
    },
    {
      "phase": 3,
      "name": "Analytics and Optimization",
      "components": [
        "Materialized views for dashboards",
        "Cloud Storage archival",
        "Advanced monitoring and alerting",
        "Performance tuning"
      ],
      "success_criteria": [
        "Dashboard queries <3 seconds",
        "Complete monitoring coverage",
        "Optimized for cost and performance"
      ],
      "estimated_duration": "2 weeks"
    }
  ],
  "cost_breakdown": {
    "ingestion": "Pub/Sub: ~$80/month for 800k messages/day (24M/month). Includes message storage and delivery.",
    "processing": "Dataflow: ~$1,200-2,000/month with 2-5 n1-standard-4 workers running 24/7. Scales with worker hours. Streaming Engine reduces costs by ~30%.",
    "storage": "BigQuery: ~$100/month for 1TB storage (compressed). Streaming inserts: ~$100/month for 24M rows. Queries vary by usage. Cloud Storage: ~$20/month for archival.",
    "optimization_tips": [
      "Use Dataflow Streaming Engine to reduce worker costs",
      "Implement Pub/Sub message compression to reduce egress",
      "Use BigQuery partition expiration to automatically clean old data",
      "Leverage BigQuery BI Engine for frequently-accessed dashboard data",
      "Right-size Dataflow workers based on actual throughput patterns",
      "Use committed use discounts for predictable Dataflow workloads"
    ]
  },
  "scalability_considerations": {
    "bottlenecks": [
      "Dataflow autoscaling lag during flash sales - pre-warm workers or increase max workers",
      "BigQuery streaming insert quota (100k rows/sec/table) - use multiple tables or Storage Write API",
      "Product catalog enrichment with side inputs - consider caching strategy"
    ],
    "scaling_strategy": [
      "Pub/Sub: Automatically scales, no action needed",
      "Dataflow: Configure autoscaling max workers to 50+ for flash sales",
      "BigQuery: Use Storage Write API for higher throughput (1M+ rows/sec)",
      "Product catalog: Pre-load into Dataflow worker memory or use distributed cache"
    ],
    "capacity_planning": "Monitor Pub/Sub backlog and Dataflow system lag. If lag exceeds 15 minutes during normal operations, increase max workers. Plan for 3x peak capacity headroom for flash sales."
  },
  "security_recommendations": {
    "iam_roles": [
      "Dataflow service account: roles/dataflow.worker, roles/bigquery.dataEditor, roles/storage.objectCreator",
      "Application publishers: roles/pubsub.publisher on topic",
      "Dashboard users: roles/bigquery.dataViewer on analytics dataset"
    ],
    "network": "Use VPC Service Controls to create security perimeter around sensitive data. Dataflow workers in private subnet with Cloud NAT for internet access if needed.",
    "encryption": "Default Google-managed encryption sufficient for most use cases. Enable CMEK (Customer-Managed Encryption Keys) for compliance requirements. Use TLS for all data in transit.",
    "compliance": "Enable audit logging for BigQuery and Dataflow. Implement data retention policies aligned with GDPR/CCPA requirements. Use column-level security in BigQuery for PII."
  },
  "example_implementation": "# Dataflow Streaming Pipeline Example (Python)\nimport apache_beam as beam\nfrom apache_beam.options.pipeline_options import PipelineOptions\n\nclass EnrichWithProduct(beam.DoFn):\n    def process(self, event, product_catalog):\n        product = product_catalog.get(event['product_id'], {})\n        event['product_name'] = product.get('name', 'Unknown')\n        event['product_category'] = product.get('category', 'Unknown')\n        yield event\n\ndef run():\n    options = PipelineOptions(\n        streaming=True,\n        project='your-project',\n        region='us-central1',\n        temp_location='gs://bucket/temp',\n        enable_streaming_engine=True,\n        max_num_workers=20,\n    )\n    \n    with beam.Pipeline(options=options) as p:\n        # Read from Pub/Sub\n        events = (p \n            | 'Read from Pub/Sub' >> beam.io.ReadFromPubSub(\n                subscription='projects/your-project/subscriptions/events-sub')\n            | 'Parse JSON' >> beam.Map(json.loads)\n            | 'Validate' >> beam.Filter(lambda x: 'event_type' in x)\n        )\n        \n        # Load product catalog as side input\n        product_catalog = (\n            p\n            | 'Read Products' >> beam.io.ReadFromBigQuery(\n                query='SELECT product_id, name, category FROM `project.dataset.products`')\n            | 'To Dict' >> beam.Map(lambda x: (x['product_id'], x))\n            | 'As Dict' >> beam.combiners.ToDict()\n        )\n        \n        # Enrich and write to BigQuery\n        (events\n            | 'Enrich' >> beam.ParDo(EnrichWithProduct(), beam.pvalue.AsSingleton(product_catalog))\n            | 'Window' >> beam.WindowInto(beam.window.FixedWindows(300))  # 5-min windows\n            | 'Write to BigQuery' >> beam.io.WriteToBigQuery(\n                table='project:dataset.events',\n                write_disposition=beam.io.BigQueryDisposition.WRITE_APPEND,\n                method='STREAMING_INSERTS')\n        )"
}
```

### Example 2: Daily Batch Data Warehouse ETL

**Input:**
```json
{
  "pipeline_purpose": "Daily ETL to load transactional data from multiple databases into BigQuery data warehouse",
  "data_sources": [
    {"type": "database", "volume": "PostgreSQL, 10M rows/day", "format": "relational"},
    {"type": "database", "volume": "MySQL, 5M rows/day", "format": "relational"},
    {"type": "file", "volume": "CSV files in GCS, 2M rows/day", "format": "csv"}
  ],
  "data_destination": "BigQuery",
  "processing_requirements": ["transformation", "aggregation", "validation", "deduplication"],
  "latency_requirement": "batch-daily",
  "cost_priority": "cost-optimized",
  "complexity_factors": ["data quality checks", "schema evolution", "incremental loads"]
}
```

**Output:**
```json
{
  "architecture_summary": {
    "pipeline_type": "batch ELT",
    "primary_services": ["BigQuery", "Data Transfer Service", "Cloud Composer", "Cloud Storage"],
    "complexity_level": "moderate",
    "estimated_monthly_cost": "$500 - $1,200 (mostly Composer and query costs)",
    "implementation_effort": "3-4 person-weeks"
  },
  "recommended_architecture": {
    "ingestion_layer": {
      "services": ["BigQuery Data Transfer Service", "Cloud Storage Transfer"],
      "rationale": "Data Transfer Service provides managed, scheduled transfers from PostgreSQL and MySQL to BigQuery. Cloud Storage already contains CSV files. Serverless and cost-effective for batch loads.",
      "configuration": {
        "data_transfer_postgresql": {
          "schedule": "Daily at 1:00 AM",
          "destination": "BigQuery raw_postgres dataset",
          "incremental_mode": "Based on updated_at timestamp column",
          "write_disposition": "WRITE_APPEND to daily partitions"
        },
        "data_transfer_mysql": {
          "schedule": "Daily at 1:30 AM",
          "destination": "BigQuery raw_mysql dataset",
          "incremental_mode": "Change data capture or timestamp-based"
        }
      }
    },
    "processing_layer": {
      "services": ["BigQuery (ELT approach)", "Dataform"],
      "rationale": "ELT pattern: Load raw data into BigQuery staging tables, then transform using SQL. BigQuery's compute scales automatically and is cost-effective for batch processing. Dataform manages SQL transformation DAG.",
      "configuration": {
        "bigquery_transformations": {
          "staging_layer": "Clean and standardize raw data",
          "intermediate_layer": "Join and denormalize",
          "marts_layer": "Business-friendly dimension and fact tables",
          "incremental_strategy": "MERGE for SCD Type 2 dimensions, INSERT for facts"
        },
        "dataform": {
          "project_structure": "staging/ -> intermediate/ -> marts/",
          "assertions": "Data quality checks as Dataform assertions",
          "scheduling": "Triggered by Cloud Composer after data loads complete"
        }
      }
    },
    "storage_layer": {
      "services": ["BigQuery"],
      "rationale": "BigQuery serves as both staging and final warehouse. Cost-effective with automatic long-term storage pricing after 90 days.",
      "configuration": {
        "datasets": {
          "raw_postgres": "Staging area for PostgreSQL data",
          "raw_mysql": "Staging area for MySQL data",
          "raw_files": "Staging area for CSV files",
          "analytics": "Production data warehouse tables"
        },
        "partition_strategy": "All fact tables partitioned by date, clustered by key dimensions"
      }
    },
    "orchestration": {
      "service": "Cloud Composer (Airflow)",
      "rationale": "Complex dependency management: wait for all source loads, run transformations in correct order, handle failures, data quality checks.",
      "configuration": {
        "dag_structure": "1. Sensor: Wait for Data Transfer jobs completion\n2. Load CSV files from GCS to BigQuery\n3. Trigger Dataform workflow (staging -> intermediate -> marts)\n4. Data quality validation queries\n5. Success/failure notifications",
        "environment_size": "Small (cost-optimized): 1 scheduler, 3 workers",
        "schedule": "Daily at 2:00 AM (after data transfers)",
        "retry_policy": "3 retries with exponential backoff"
      }
    },
    "monitoring": {
      "services": ["Cloud Monitoring", "Cloud Logging", "BigQuery INFORMATION_SCHEMA"],
      "key_metrics": [
        "Data Transfer Service: Job success/failure, row counts, transfer duration",
        "BigQuery: Bytes processed, query duration, table row counts",
        "Composer: DAG run duration, task failures, queue depth",
        "Custom: Data quality check results, data freshness"
      ],
      "alerting_strategy": "Email alerts for DAG failures or data quality issues. Daily summary report of pipeline metrics."
    }
  },
  "architecture_diagram": "PostgreSQL    MySQL    GCS (CSV files)\n     |          |            |\n     v          v            |\n  Data Transfer Service     |\n     |          |            |\n     v          v            v\n BigQuery Staging (raw_* datasets)\n            |\n            v\n    Cloud Composer DAG\n            |\n            +---> Dataform Workflow\n            |        |\n            |        +---> Staging Layer (clean, standardize)\n            |        +---> Intermediate Layer (joins, enrichment)\n            |        +---> Marts Layer (facts, dimensions)\n            |\n            +---> Data Quality Checks\n            |\n            v\n    BigQuery Analytics (production warehouse)\n            |\n            v\n    Looker / Data Studio",
  "alternative_architectures": [
    {
      "approach": "Dataflow for transformations instead of BigQuery SQL",
      "trade_offs": "Pros: Better for complex transformations, can write to multiple sinks. Cons: Higher cost, more complex code, longer development time.",
      "use_case": "Use if transformations are very complex or need to output to non-BigQuery destinations"
    },
    {
      "approach": "dbt Cloud instead of Dataform",
      "trade_offs": "Pros: Richer testing framework, better documentation, larger community. Cons: Additional cost for dbt Cloud, less native GCP integration.",
      "use_case": "Use if team has dbt experience or needs advanced testing/documentation features"
    }
  ],
  "implementation_phases": [
    {
      "phase": 1,
      "name": "Basic Data Ingestion",
      "components": [
        "Set up Data Transfer Service for databases",
        "Create BigQuery staging datasets and tables",
        "Manual CSV loads to validate schema",
        "Basic Composer DAG for orchestration"
      ],
      "success_criteria": [
        "Data successfully loaded from all sources",
        "DAG runs successfully end-to-end",
        "Row counts match source systems"
      ],
      "estimated_duration": "1-2 weeks"
    },
    {
      "phase": 2,
      "name": "ELT Transformations",
      "components": [
        "Dataform project with staging/intermediate/marts layers",
        "Incremental load logic for dimensions and facts",
        "Integration with Composer DAG"
      ],
      "success_criteria": [
        "All transformation logic migrated to Dataform",
        "Analytics tables populated correctly",
        "Incremental loads working properly"
      ],
      "estimated_duration": "2 weeks"
    },
    {
      "phase": 3,
      "name": "Data Quality and Monitoring",
      "components": [
        "Dataform assertions for data quality",
        "Monitoring dashboards",
        "Alerting policies",
        "Performance optimization"
      ],
      "success_criteria": [
        "Data quality checks in place for all critical tables",
        "Alerts configured and tested",
        "Pipeline runs in <60 minutes"
      ],
      "estimated_duration": "1 week"
    }
  ],
  "cost_breakdown": {
    "ingestion": "Data Transfer Service: ~$50/month for two database connections. BigQuery loads: Minimal (loading is free, only storage charged).",
    "processing": "BigQuery queries: ~$100-300/month depending on transformation complexity and data volume. Dataform: Free (open-source, self-hosted in Composer).",
    "storage": "BigQuery: ~$200/month for 10TB (assumes 6-month retention with long-term storage discount). First 10GB free.",
    "orchestration": "Cloud Composer: ~$300-400/month for small environment (1 scheduler, 3 workers). Largest ongoing cost component.",
    "optimization_tips": [
      "Use BigQuery partition expiration to manage storage costs",
      "Minimize Composer environment size - small is sufficient for daily batch",
      "Use BigQuery scheduled queries instead of Composer for simple transformations",
      "Leverage BigQuery's long-term storage discount (50% off after 90 days)",
      "Consider Workflows instead of Composer if orchestration is simple",
      "Use incremental transformations to reduce query costs"
    ]
  },
  "scalability_considerations": {
    "bottlenecks": [
      "Data Transfer Service has limits on table size and row count - may need custom Dataflow for very large tables",
      "Composer scheduler can bottleneck with >100 concurrent tasks - increase scheduler resources if needed",
      "BigQuery query slots - monitor slot usage, consider reservations for predictable costs"
    ],
    "scaling_strategy": [
      "Data Transfer Service: Partition large tables by date for incremental loads",
      "BigQuery: Automatically scales, monitor slot usage for reservation planning",
      "Composer: Increase workers (vertically or horizontally) as DAG complexity grows",
      "Add parallelization in DAG to process independent tables simultaneously"
    ],
    "capacity_planning": "Current 17M rows/day is well within limits. Can scale to 100M+ rows/day with same architecture. Monitor Composer queue depth and task duration - if tasks wait >10 min, increase workers."
  },
  "security_recommendations": {
    "iam_roles": [
      "Data Transfer Service account: roles/bigquery.dataEditor on staging datasets",
      "Composer workers: roles/bigquery.dataEditor, roles/dataform.editor",
      "BI users: roles/bigquery.dataViewer on analytics dataset only",
      "Data engineers: roles/bigquery.admin for development"
    ],
    "network": "Composer in private IP mode with Cloud SQL proxy for database connectivity. Use VPC peering or private service connect for database connections.",
    "encryption": "Default encryption sufficient. Enable Cloud KMS CMEK if regulatory requirements demand.",
    "compliance": "Enable BigQuery audit logs. Implement column-level security for PII. Use authorized views to restrict access to sensitive columns."
  },
  "example_implementation": "# Composer DAG Example\nfrom airflow import DAG\nfrom airflow.providers.google.cloud.sensors.bigquery import BigQueryTableExistenceSensor\nfrom airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator\nfrom airflow.operators.bash import BashOperator\n\ndefault_args = {\n    'owner': 'data-team',\n    'retries': 3,\n    'retry_delay': timedelta(minutes=5),\n}\n\nwith DAG('daily_dwh_pipeline',\n         default_args=default_args,\n         schedule_interval='0 2 * * *',  # 2 AM daily\n         catchup=False) as dag:\n    \n    # Wait for Data Transfer jobs to complete\n    wait_postgres = BigQueryTableExistenceSensor(\n        task_id='wait_postgres_transfer',\n        project_id='project',\n        dataset_id='raw_postgres',\n        table_id='transactions${{ ds_nodash }}',  # Check today's partition exists\n    )\n    \n    # Load CSV from GCS\n    load_csv = BigQueryInsertJobOperator(\n        task_id='load_csv_files',\n        configuration={\n            'load': {\n                'sourceUris': ['gs://bucket/data/{{ ds }}/*.csv'],\n                'destinationTable': {\n                    'projectId': 'project',\n                    'datasetId': 'raw_files',\n                    'tableId': 'imports${{ ds_nodash }}'\n                },\n                'sourceFormat': 'CSV',\n                'autodetect': True,\n                'writeDisposition': 'WRITE_TRUNCATE',\n            }\n        },\n    )\n    \n    # Run Dataform workflow\n    run_dataform = BashOperator(\n        task_id='run_dataform_workflow',\n        bash_command='dataform run --project=project --location=us-central1',\n    )\n    \n    # Data quality check\n    quality_check = BigQueryInsertJobOperator(\n        task_id='data_quality_check',\n        configuration={\n            'query': {\n                'query': '{% include \"sql/quality_checks.sql\" %}',\n                'useLegacySql': False,\n            }\n        },\n    )\n    \n    [wait_postgres, load_csv] >> run_dataform >> quality_check"
}
```

## Constraints

- Service selection must align with data latency requirements (can't use daily batch for real-time needs)
- Consider regional availability of GCP services
- Respect GCP service quotas and limits (e.g., Pub/Sub message size, BigQuery load job limits)
- Architecture must be cost-effective for stated budget priority
- Implementation complexity should match team expertise
- Ensure chosen services support required data formats and protocols
- Consider vendor lock-in implications if multi-cloud is a future requirement

## Success Criteria

- [ ] Recommended architecture meets latency requirements
- [ ] All data sources have clear ingestion paths
- [ ] Processing layer handles all specified transformations
- [ ] Service selections have clear rationale
- [ ] Cost estimates are provided with optimization tips
- [ ] Scalability and bottlenecks are addressed
- [ ] Security recommendations cover IAM, network, and encryption
- [ ] Implementation is phased with clear milestones
- [ ] Alternative architectures considered with trade-offs
- [ ] Monitoring strategy covers all critical components
- [ ] Example implementation code provided for key components

## Dependencies

- Understanding of GCP service capabilities and limitations
- Knowledge of data engineering patterns (batch, streaming, ELT, ETL)
- Familiarity with cost models for each GCP service
- Understanding of data latency and throughput requirements
- Knowledge of orchestration tool capabilities (Composer, Scheduler, Workflows)

## Composition Notes

This skill works well with:
- **bigquery-schema-design**: Design table schemas that align with pipeline architecture
- **etl-pattern-selection**: Choose between ETL and ELT based on architecture
- **data-quality-validation**: Integrate validation into pipeline architecture
- **bigquery-query-optimization**: Optimize queries used in transformation layer

Use architecture output to:
- Design detailed component implementations
- Create infrastructure-as-code (Terraform) configurations
- Develop monitoring and alerting strategies
- Plan implementation roadmap and sprints
- Estimate project costs and timelines
