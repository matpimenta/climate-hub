# GCP Data Platform Architecture

## Executive Summary

This document describes a comprehensive, extensible GCP-based data platform designed to ingest data from numerous sources, process it for multiple purposes, and serve it through various interfaces. The platform prioritizes rapid onboarding of new data sources (minutes, not days) while maintaining scalability, reliability, and cost-effectiveness.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Core Design Principles](#core-design-principles)
3. [Roles and Responsibilities](#roles-and-responsibilities)
4. [Platform Layers](#platform-layers)
5. [Ingestion Patterns](#ingestion-patterns)
6. [Data Architecture](#data-architecture)
7. [Processing Pipelines](#processing-pipelines)
8. [Serving Layer](#serving-layer)
9. [Extensibility Framework](#extensibility-framework)
10. [Onboarding Process](#onboarding-process)
11. [Security & Governance](#security--governance)
12. [Monitoring & Operations](#monitoring--operations)
13. [Cost Optimization](#cost-optimization)

## Architecture Overview

The platform is built on Google Cloud Platform using a modern, cloud-native architecture that separates concerns into distinct layers:

- **Ingestion Layer**: Multiple patterns for data acquisition
- **Storage Layer**: Multi-zone data lake (Bronze/Silver/Gold)
- **Processing Layer**: Batch and stream processing pipelines
- **Serving Layer**: Purpose-built interfaces for different consumers
- **Orchestration Layer**: Workflow management and scheduling
- **Governance Layer**: Metadata, lineage, and access control

### Key Technologies

| Component | GCP Service | Purpose |
|-----------|-------------|---------|
| Message Bus | Cloud Pub/Sub | Central event hub for all data ingestion |
| Stream Processing | Dataflow | Real-time and batch data processing |
| Data Lake | Cloud Storage (GCS) | Raw and processed data storage |
| Data Warehouse | BigQuery | Analytics, reporting, and ML features |
| API Gateway | Cloud Endpoints / Apigee | Third-party data access |
| Workflow Orchestration | Cloud Composer (Airflow) | Pipeline scheduling and dependencies |
| Metadata Catalog | Data Catalog | Schema registry and data discovery |
| ML Platform | Vertex AI | Model training and serving |
| Monitoring | Cloud Monitoring & Logging | Observability |
| Security | Secret Manager, IAM, VPC-SC | Access control and secrets |

See `diagrams/overall-architecture.mmd` for visual representation.

## Core Design Principles

### 1. Configuration-Driven Architecture
- New data sources defined via YAML configuration
- Auto-generation of ingestion pipelines from templates
- Schema-on-read for maximum flexibility

### 2. Separation of Concerns
- Decoupled ingestion, processing, and serving
- Single responsibility per component
- Event-driven communication via Pub/Sub

### 3. Scalability First
- Horizontally scalable components
- Auto-scaling based on load
- Partition strategies for large datasets

### 4. Reliability & Resilience
- Dead-letter queues for failed messages
- Retry policies with exponential backoff
- Data validation at ingestion boundaries

### 5. Cost Optimization
- Storage tiering (Standard → Nearline → Coldline)
- BigQuery partitioning and clustering
- Spot instances for batch processing

## Roles and Responsibilities

Successfully executing this data platform architecture requires a diverse team with clearly defined roles and responsibilities. This section outlines all the roles needed, their key responsibilities, required skills, and how they collaborate.

### Executive Roles

#### 1. Data Platform Lead / Head of Data Engineering
**Accountability**: Overall platform success, strategy, and team management

**Key Responsibilities**:
- Define platform vision and roadmap
- Manage budget and resource allocation
- Stakeholder management (executive leadership, business units)
- Make architectural decisions and trade-offs
- Ensure alignment with business objectives
- Risk management and compliance oversight
- Team hiring, development, and retention
- Define SLAs and success metrics

**Required Skills**:
- 8+ years in data engineering/platform engineering
- Strong understanding of GCP and cloud-native architectures
- Leadership and people management
- Budget management and vendor negotiations
- Strategic thinking and business acumen

**Key Metrics**:
- Platform uptime and reliability
- Time-to-onboard new data sources
- Cost per GB processed
- Team satisfaction and retention
- Stakeholder satisfaction scores

---

### Core Technical Roles

#### 2. Platform Architect
**Accountability**: Technical architecture design, standards, and evolution

**Key Responsibilities**:
- Design overall platform architecture and data flows
- Define technical standards and best practices
- Evaluate and select GCP services and tools
- Create reference architectures and patterns
- Review and approve major architectural changes
- Performance and scalability planning
- Disaster recovery and business continuity planning
- Technology radar and emerging tech evaluation

**Required Skills**:
- Deep expertise in GCP services (BigQuery, Dataflow, Pub/Sub, etc.)
- Strong background in distributed systems
- Data modeling and schema design
- Security and compliance knowledge
- Performance optimization
- Infrastructure as Code (Terraform)

**Collaborates With**: All technical roles, Security Engineer, Product Managers

**Deliverables**:
- Architecture Decision Records (ADRs)
- Reference architectures and diagrams
- Technical design documents
- Capacity planning models

---

#### 3. Senior Data Engineer (2-3 people)
**Accountability**: Build and maintain core platform components

**Key Responsibilities**:
- Develop reusable connector templates
- Build and optimize Dataflow pipelines
- Implement Bronze → Silver → Gold transformations
- Create data quality frameworks
- Develop automation scripts and tools
- Mentor junior engineers
- Code reviews and technical guidance
- Troubleshoot complex data issues
- Performance tuning of pipelines

**Required Skills**:
- Expert in Python, Java, or Scala
- Apache Beam / Dataflow expertise
- BigQuery optimization
- SQL mastery
- CI/CD and DevOps practices
- Data quality and testing frameworks

**Collaborates With**: Platform Architect, DevOps Engineers, Data Analysts

**Typical Projects**:
- Build CDC connector for PostgreSQL
- Optimize slow-running aggregation pipeline
- Implement data quality framework
- Create self-service connector deployment tool

---

#### 4. Data Engineer (3-5 people)
**Accountability**: Implement data sources, pipelines, and transformations

**Key Responsibilities**:
- Onboard new data sources
- Write and maintain ETL/ELT pipelines
- Implement business logic transformations
- Create and maintain schemas
- Write data quality tests
- Monitor pipeline health
- Respond to data incidents
- Document data flows and processes
- Support data analysts and scientists

**Required Skills**:
- Proficient in Python or Java
- SQL (intermediate to advanced)
- GCP services (BigQuery, Dataflow, GCS)
- Data modeling
- Git and version control
- Basic Terraform knowledge

**Collaborates With**: Senior Data Engineers, Analytics Engineers, Data Analysts

**Daily Activities**:
- Deploy new connector configurations
- Fix failed pipeline runs
- Add new transformations to Gold layer
- Update schemas for API changes
- Respond to Slack alerts

---

#### 5. DevOps / Platform Engineer (1-2 people)
**Accountability**: Infrastructure, CI/CD, and platform reliability

**Key Responsibilities**:
- Manage Terraform infrastructure as code
- Build and maintain CI/CD pipelines
- Automate deployment processes
- Configure monitoring and alerting
- Implement auto-scaling policies
- Manage GCP projects and permissions
- Optimize infrastructure costs
- Disaster recovery testing
- Security hardening
- Capacity planning and provisioning

**Required Skills**:
- Expert in Terraform and Infrastructure as Code
- GCP administration and IAM
- CI/CD tools (Cloud Build, GitHub Actions)
- Kubernetes / GKE (for Cloud Run/Composer)
- Scripting (Bash, Python)
- Monitoring tools (Cloud Monitoring, Prometheus)
- Security best practices

**Collaborates With**: Data Engineers, Security Engineer, SRE

**Key Projects**:
- Automate connector deployment pipeline
- Implement multi-region failover
- Set up cost anomaly detection
- Build self-service portal for data source onboarding

---

#### 6. Analytics Engineer (2-3 people)
**Accountability**: Gold layer data modeling and business logic

**Key Responsibilities**:
- Design dimensional models and star schemas
- Build dbt models for Gold layer
- Create business metrics and KPIs
- Implement slowly changing dimensions (SCDs)
- Build materialized views for reporting
- Optimize query performance
- Document data definitions and business logic
- Create data dictionaries
- Support report development

**Required Skills**:
- Advanced SQL and BigQuery
- dbt (data build tool)
- Data modeling (Kimball, Data Vault)
- Business intelligence concepts
- Git and version control
- Basic Python for data transformations

**Collaborates With**: Data Engineers, Data Analysts, Business Stakeholders

**Deliverables**:
- dbt models for customer 360 view
- Materialized views for daily sales dashboard
- Slowly changing dimension for product catalog
- Data dictionary and business glossary

---

#### 7. ML Engineer / MLOps Engineer (1-2 people)
**Accountability**: ML feature store, model pipelines, and serving infrastructure

**Key Responsibilities**:
- Design and implement Vertex AI Feature Store
- Build feature engineering pipelines
- Create ML training and serving pipelines
- Implement model versioning and registry
- Build A/B testing framework
- Monitor model performance and drift
- Optimize inference latency
- Integrate ML models with serving layer
- Automate model retraining workflows

**Required Skills**:
- Python and ML frameworks (TensorFlow, PyTorch, scikit-learn)
- Vertex AI and BigQuery ML
- Feature engineering
- MLOps best practices
- Docker and containerization
- Model monitoring and observability

**Collaborates With**: Data Scientists, Data Engineers, Backend Engineers

**Key Projects**:
- Build customer churn prediction feature pipeline
- Implement real-time feature serving API
- Create automated model retraining DAG
- Set up model drift detection

---

#### 8. Backend / API Engineer (1-2 people)
**Accountability**: Third-party API serving layer

**Key Responsibilities**:
- Build and maintain REST APIs (FastAPI, Flask)
- Implement authentication and authorization (OAuth 2.0)
- Design API endpoints and data contracts
- Implement rate limiting and throttling
- Optimize API performance
- Write API documentation (OpenAPI)
- Implement caching strategies
- Monitor API usage and errors
- Handle API versioning

**Required Skills**:
- Python (FastAPI, Flask) or Go
- RESTful API design
- OAuth 2.0 and API security
- Cloud Run or GKE
- OpenAPI / Swagger
- Database query optimization
- Caching (Redis, Memcached)

**Collaborates With**: Data Engineers, Frontend Engineers, Product Managers

**Deliverables**:
- REST API for customer data access
- OAuth 2.0 authentication flow
- API rate limiting and usage tracking
- OpenAPI documentation portal

---

### Data Roles

#### 9. Data Analyst (2-4 people)
**Accountability**: Reporting, dashboards, and data insights

**Key Responsibilities**:
- Build Looker dashboards and reports
- Write SQL queries for ad-hoc analysis
- Define reporting requirements
- Validate data quality in reports
- Support business stakeholders
- Document report definitions
- Create data visualizations
- Perform exploratory data analysis
- Translate business questions into data queries

**Required Skills**:
- SQL (intermediate)
- Looker or Data Studio
- Data visualization best practices
- Statistical analysis
- Business domain knowledge
- Communication skills

**Collaborates With**: Analytics Engineers, Business Stakeholders

**Key Activities**:
- Build executive sales dashboard
- Create weekly revenue reports
- Analyze customer churn trends
- Support product team with usage metrics

---

#### 10. Data Scientist (1-2 people)
**Accountability**: ML models, predictive analytics, and experimentation

**Key Responsibilities**:
- Develop predictive models and algorithms
- Define feature requirements
- Conduct A/B tests and experiments
- Analyze model performance
- Communicate insights to stakeholders
- Collaborate on feature engineering
- Prototype new ML use cases
- Evaluate model fairness and bias

**Required Skills**:
- Python, R, or SQL
- Statistical modeling
- Machine learning algorithms
- Jupyter notebooks
- Data visualization
- Experimentation and A/B testing
- Communication and storytelling

**Collaborates With**: ML Engineers, Analytics Engineers, Product Managers

**Projects**:
- Build customer lifetime value model
- Develop product recommendation engine
- Analyze pricing experiment results
- Create churn prediction model

---

### Supporting Roles

#### 11. Security Engineer / Security Architect (0.5-1 FTE)
**Accountability**: Platform security, compliance, and data governance

**Key Responsibilities**:
- Define security policies and standards
- Implement IAM roles and permissions
- Configure VPC Service Controls
- Manage encryption keys (CMEK)
- Conduct security reviews
- Implement DLP policies for PII
- Ensure compliance (GDPR, CCPA, SOC 2)
- Security incident response
- Vulnerability management
- Audit log review

**Required Skills**:
- GCP security (IAM, VPC-SC, CMEK)
- Compliance frameworks (GDPR, CCPA, SOC 2)
- Data privacy and PII handling
- Security auditing
- Threat modeling

**Collaborates With**: Platform Architect, DevOps Engineers, Legal/Compliance

**Deliverables**:
- IAM role matrix
- Data classification policy
- PII handling procedures
- Security audit reports

---

#### 12. Site Reliability Engineer (SRE) (0.5-1 FTE)
**Accountability**: Platform reliability, incident response, and performance

**Key Responsibilities**:
- Define and monitor SLIs/SLOs/SLAs
- On-call rotation and incident response
- Post-incident reviews and RCAs
- Capacity planning
- Performance optimization
- Reliability testing (chaos engineering)
- Runbook development
- Toil reduction and automation
- Create and maintain observability dashboards

**Required Skills**:
- GCP operations and troubleshooting
- Monitoring and alerting (Cloud Monitoring)
- Incident management
- Performance analysis
- Automation scripting
- On-call experience

**Collaborates With**: DevOps Engineers, Data Engineers

**Key Activities**:
- Respond to pipeline failures at 2 AM
- Conduct monthly disaster recovery drills
- Reduce manual intervention through automation
- Analyze and improve pipeline SLAs

---

#### 13. Technical Writer / Documentation Specialist (0.5 FTE)
**Accountability**: Platform documentation and training materials

**Key Responsibilities**:
- Write user guides and tutorials
- Create onboarding documentation
- Maintain architecture documentation
- Document APIs and schemas
- Create video tutorials
- Build internal wiki/knowledge base
- Write runbooks
- Keep documentation up-to-date

**Required Skills**:
- Technical writing
- Markdown, Confluence, or similar tools
- Diagramming (Mermaid, Draw.io)
- Basic understanding of data concepts
- Video editing (for tutorials)

**Collaborates With**: All technical roles

**Deliverables**:
- "Onboarding a New Data Source" tutorial
- API documentation portal
- Troubleshooting guides
- Monthly "What's New" newsletter

---

#### 14. Product Manager - Data Platform (1 person)
**Accountability**: Platform roadmap, prioritization, and stakeholder management

**Key Responsibilities**:
- Define platform vision and roadmap
- Prioritize features and projects
- Gather requirements from stakeholders
- Manage backlog and sprint planning
- Define success metrics
- Communicate status to leadership
- Coordinate cross-team dependencies
- Conduct user research
- Balance technical debt vs. new features

**Required Skills**:
- Product management experience
- Understanding of data platforms
- Stakeholder management
- Agile methodologies
- Data-driven decision making
- Communication skills

**Collaborates With**: Platform Lead, all engineering roles, business stakeholders

**Key Activities**:
- Quarterly roadmap planning
- Weekly sprint planning
- Monthly stakeholder demos
- User feedback sessions

---

### Governance and Operations Roles

#### 15. Data Steward / Data Governance Lead (0.5-1 FTE)
**Accountability**: Data quality, metadata, and governance policies

**Key Responsibilities**:
- Define data governance policies
- Manage Data Catalog and metadata
- Define data quality standards
- Maintain business glossary
- Resolve data ownership questions
- Coordinate data classification
- Track data lineage
- Manage master data
- Handle data access requests

**Required Skills**:
- Data governance frameworks
- Metadata management
- Data Catalog (GCP)
- Business domain knowledge
- Policy development
- Communication skills

**Collaborates With**: All data roles, Legal, Compliance

**Deliverables**:
- Data governance framework
- Business glossary with 500+ terms
- Data quality scorecards
- Data access policies

---

#### 16. FinOps Analyst (0.25-0.5 FTE)
**Accountability**: Cost optimization and financial management

**Key Responsibilities**:
- Track and forecast GCP costs
- Identify cost optimization opportunities
- Allocate costs to business units
- Create cost dashboards
- Recommend reserved capacity purchases
- Monitor budget alerts
- Conduct cost-benefit analyses
- Implement cost allocation tags

**Required Skills**:
- GCP billing and cost management
- SQL and data analysis
- Financial modeling
- Data visualization

**Collaborates With**: Platform Lead, DevOps Engineers, Finance

**Key Metrics**:
- Monthly GCP spend
- Cost per GB processed
- Cost per API request
- Unused resource identification

---

### External / Partner Roles

#### 17. Business Stakeholders / Data Consumers
**Accountability**: Define requirements and consume data products

**Key Responsibilities**:
- Define business requirements
- Provide feedback on data quality
- Use dashboards and reports
- Request new data sources
- Validate data accuracy
- Participate in UAT

**Examples**:
- Sales Operations team
- Marketing Analytics team
- Finance team
- Product Managers
- Executive leadership

---

#### 18. Third-Party API Consumers
**Accountability**: Integrate with platform APIs and provide feedback

**Key Responsibilities**:
- Integrate applications with platform APIs
- Report API issues and bugs
- Request new API features
- Comply with rate limits and terms of service

**Examples**:
- Partner companies
- Vendor integrations
- Internal applications (not on GCP)

---

## Team Structure and Sizing

### Phase 1: Foundation Team (Months 1-6)
**Team Size**: 8-10 people

- 1 Platform Architect
- 2 Senior Data Engineers
- 2 Data Engineers
- 1 DevOps Engineer
- 1 Analytics Engineer
- 0.5 Security Engineer (shared)
- 0.5 Product Manager (shared)

**Focus**: Build core platform, onboard first 5-10 data sources

---

### Phase 2: Growth Team (Months 7-12)
**Team Size**: 12-15 people

- Add: 1 Data Engineer
- Add: 1 Analytics Engineer
- Add: 1 Backend Engineer
- Add: 1 ML Engineer
- Add: 2 Data Analysts
- Add: 0.5 SRE (shared)
- Add: 0.5 Technical Writer (shared)

**Focus**: Scale to 50+ data sources, build serving layers

---

### Phase 3: Mature Team (Months 13+)
**Team Size**: 15-20 people

- Add: 1-2 Data Engineers
- Add: 1 Data Scientist
- Add: 1 Data Analyst
- Add: 0.5 Data Steward
- Add: 0.25 FinOps Analyst

**Focus**: 100+ data sources, advanced ML, cost optimization

---

## RACI Matrix for Key Activities

| Activity | Platform Lead | Architect | Sr. Data Eng. | Data Eng. | DevOps | Analytics Eng. | Product Mgr | Security |
|----------|--------------|-----------|---------------|-----------|--------|----------------|-------------|----------|
| Platform Strategy | A | R | C | I | I | I | C | I |
| Architecture Design | A | R | C | I | C | I | I | C |
| Onboard Data Source | I | C | R | A | C | I | C | C |
| Build Pipeline | C | C | R | A | C | C | I | I |
| Deploy Infrastructure | C | C | C | I | A/R | I | I | C |
| Design Gold Models | C | C | C | I | I | A/R | C | I |
| Build API Endpoints | C | C | C | I | C | I | C | C |
| Define Security Policy | A | C | I | I | C | I | I | R |
| Incident Response | I | C | R | A | R | I | I | C |
| Cost Optimization | A | C | C | C | R | I | C | I |

**Legend**:
- R = Responsible (does the work)
- A = Accountable (final decision maker)
- C = Consulted (provides input)
- I = Informed (kept in the loop)

---

## Role Evolution and Career Paths

### Career Ladder for Data Engineers

1. **Junior Data Engineer** (0-2 years)
   - Onboard data sources from templates
   - Write simple transformations
   - Fix pipeline bugs

2. **Data Engineer** (2-4 years)
   - Build custom connectors
   - Design pipeline architectures
   - Mentor juniors

3. **Senior Data Engineer** (4-7 years)
   - Design complex data flows
   - Create reusable frameworks
   - Lead technical initiatives

4. **Staff Data Engineer / Principal** (7+ years)
   - Platform-wide technical leadership
   - Define standards and patterns
   - Cross-team collaboration

5. **Platform Architect / Engineering Manager**
   - Architectural leadership OR people management
   - Strategic planning
   - Organizational impact

---

## Key Competencies by Role

### For All Technical Roles
- GCP fundamentals
- SQL proficiency
- Git and version control
- Agile methodologies
- Communication skills
- Problem-solving

### For Engineering Roles (Additional)
- Programming (Python, Java, or Go)
- Infrastructure as Code
- CI/CD
- Testing and quality assurance
- Performance optimization

### For Leadership Roles (Additional)
- Strategic thinking
- Stakeholder management
- Budget management
- Team development
- Risk management

---

## Hiring Priorities

### Immediate Needs (Months 1-3)
1. Platform Architect (critical path)
2. Senior Data Engineer (2 people for core platform)
3. DevOps Engineer (infrastructure foundation)

### Near-term (Months 4-6)
4. Data Engineers (2 people for source onboarding)
5. Analytics Engineer (Gold layer modeling)
6. Security Engineer (part-time/consultant)

### Medium-term (Months 7-12)
7. Backend Engineer (API development)
8. ML Engineer (feature store)
9. Data Analysts (2 people for reporting)
10. SRE (reliability and on-call)

---

## Collaboration Patterns

### Daily
- Engineering team standup (15 min)
- Incident response (as needed)
- Slack-based collaboration

### Weekly
- Platform team sync (1 hour)
- Backlog grooming (1 hour)
- Office hours for data consumers (1 hour)

### Bi-weekly
- Sprint planning (2 hours)
- Sprint review and demo (1 hour)
- Retrospective (1 hour)

### Monthly
- Architecture review board (2 hours)
- Security review (1 hour)
- Cost review (1 hour)
- All-hands platform update (30 min)

### Quarterly
- Roadmap planning (half day)
- OKR setting and review
- Training and development

---

## Success Metrics by Role

### Platform Lead
- Platform uptime: 99.9%+
- Data sources onboarded per quarter: 20+
- Team satisfaction (NPS): 8+/10
- Stakeholder satisfaction: 80%+

### Data Engineers
- Pipelines deployed per sprint: 5-10
- Mean time to onboard data source: <30 min
- Pipeline success rate: 98%+
- Code review turnaround: <24 hours

### DevOps Engineers
- Infrastructure deployment time: <10 min
- Incident response time: <15 min
- Cost reduction initiatives: 2+ per quarter
- Automation coverage: 80%+

### Analytics Engineers
- dbt models delivered: 10+ per month
- Query performance improvement: 20%+ per quarter
- Documentation coverage: 90%+

### Data Analysts
- Dashboards delivered: 5+ per month
- Average query response time: <5 sec
- Report accuracy: 99%+

---

## Training and Development

### Onboarding Program (First 30 Days)
- Week 1: GCP fundamentals, platform overview
- Week 2: Hands-on with tooling (Terraform, Dataflow, BigQuery)
- Week 3: Onboard first data source (with mentor)
- Week 4: Deploy first pipeline independently

### Ongoing Training
- Monthly "Lunch & Learn" sessions
- Quarterly GCP certification goals
- Conference attendance (1-2 per year)
- Internal tech talks
- Pair programming sessions

### Recommended Certifications
- GCP Professional Data Engineer
- GCP Professional Cloud Architect
- Terraform Associate
- dbt Analytics Engineering
- Certified Kubernetes Administrator (for DevOps)

---

## On-Call and Incident Management

### On-Call Rotation
- **Primary**: Senior Data Engineer or SRE
- **Secondary**: Data Engineer
- **Escalation**: Platform Architect or Platform Lead

### On-Call Schedule
- 24/7 coverage (with follow-the-sun if global team)
- 1-week rotations
- Compensated with time off

### Incident Response Roles
- **Incident Commander**: On-call engineer
- **Communications Lead**: Product Manager or Platform Lead
- **Technical Lead**: Senior Engineer or Architect (for complex issues)

---

## Communication and Collaboration Tools

### Core Tools
- **Slack**: Daily communication, alerts
- **Jira**: Sprint planning, issue tracking
- **Confluence**: Documentation, wiki
- **GitHub**: Code repository, reviews
- **Figma/Draw.io**: Diagramming
- **Looker**: Dashboards and reports
- **PagerDuty**: On-call alerts

### Meeting Cadence
- **Daily Standup**: 15 min, async-friendly
- **Sprint Planning**: Every 2 weeks, 2 hours
- **Architecture Review**: Monthly, 2 hours
- **All-Hands**: Monthly, 30 min

---

This comprehensive role definition ensures clarity, accountability, and efficient collaboration across the entire data platform team.

## Platform Layers

### 1. Ingestion Layer

**Purpose**: Acquire data from diverse sources using appropriate patterns.

**Components**:
- **Cloud Pub/Sub**: Central message bus (all ingestion routes through here)
- **Cloud Functions**: Lightweight connectors for APIs and webhooks
- **Cloud Run**: Containerized connectors for complex sources
- **Transfer Service**: Managed transfers from other clouds (S3, Azure Blob)
- **Datastream**: Change Data Capture (CDC) from databases
- **Storage Transfer**: Scheduled file transfers

**Design Pattern**:
```
Data Source → Connector → Pub/Sub Topic → Dataflow → Storage
```

All connectors publish to Pub/Sub topics, enabling:
- Standardized interface for processing layer
- Multiple subscribers for different purposes
- Replay capability for reprocessing
- Decoupling of source and destination

### 2. Storage Layer

**Multi-Zone Architecture**:

#### Bronze Zone (Raw Data)
- **Location**: GCS buckets (regional)
- **Format**: Original format (JSON, CSV, Avro, Parquet)
- **Purpose**: Immutable source of truth
- **Retention**: Long-term (7+ years with lifecycle policies)
- **Naming**: `gs://bronze-{project}-{region}/source={source_name}/date={YYYY-MM-DD}/`

#### Silver Zone (Processed Data)
- **Location**: GCS + BigQuery external tables
- **Format**: Parquet (columnar, compressed)
- **Purpose**: Cleaned, validated, standardized data
- **Transformations**: Data quality checks, schema validation, deduplication
- **Naming**: `gs://silver-{project}-{region}/dataset={dataset_name}/table={table_name}/`

#### Gold Zone (Curated Data)
- **Location**: BigQuery native tables
- **Format**: BigQuery optimized (partitioned, clustered)
- **Purpose**: Business-ready datasets for analytics and ML
- **Transformations**: Aggregations, denormalization, feature engineering
- **Organization**: By domain (e.g., `gold.customer_360`, `gold.product_analytics`)

### 3. Processing Layer

**Stream Processing**:
- **Technology**: Dataflow (Apache Beam)
- **Use Cases**: Real-time transformations, windowed aggregations
- **Patterns**:
  - Pub/Sub → Dataflow → BigQuery (hot path)
  - Pub/Sub → Dataflow → GCS (cold path)

**Batch Processing**:
- **Technology**: Dataflow + BigQuery SQL
- **Use Cases**: Daily aggregations, ML feature generation, data quality checks
- **Scheduling**: Cloud Composer DAGs

**Processing Framework**:
```python
# Reusable Beam pipeline template
class StandardPipeline:
    - Read from Pub/Sub
    - Parse and validate
    - Apply transformations (pluggable)
    - Write to Bronze (raw)
    - Write to Silver (processed)
    - Publish metadata events
```

### 4. Serving Layer

**Three Purpose-Built Serving Patterns**:

#### A. Third-Party Data Access
- **Technology**: Cloud Endpoints + Cloud Run + BigQuery
- **Architecture**:
  ```
  API Gateway → Cloud Run (REST API) → BigQuery (Gold zone)
  ```
- **Features**:
  - OAuth 2.0 authentication
  - Rate limiting per client
  - Data masking/filtering by client
  - Usage tracking and billing
  - OpenAPI documentation

#### B. Reporting & Dashboards
- **Technology**: BigQuery + Looker/Data Studio + Cloud CDN
- **Architecture**:
  ```
  BigQuery (Gold) → Materialized Views → Looker → Website
  ```
- **Features**:
  - Pre-aggregated tables for fast queries
  - Scheduled refreshes
  - Row-level security
  - Embedded dashboards
  - Export to PDF/CSV

#### C. AI/ML Model Features
- **Technology**: Vertex AI + BigQuery ML
- **Architecture**:
  ```
  BigQuery (Gold) → Feature Store → Vertex AI → Model Serving
  ```
- **Features**:
  - Centralized feature store
  - Point-in-time correctness
  - Feature versioning
  - Online and offline serving
  - A/B testing framework

### 5. Orchestration Layer

**Cloud Composer (Managed Airflow)**:
- DAG-based workflow management
- Dependencies between pipelines
- Sensor operators for external triggers
- SLA monitoring and alerting

**Standard DAG Pattern**:
```python
# Example: Daily processing DAG
DAG:
  - Check source data availability
  - Trigger ingestion (if new data)
  - Run data quality checks
  - Process Bronze → Silver → Gold
  - Update materialized views
  - Trigger downstream consumers
  - Send completion notifications
```

### 6. Governance Layer

**Data Catalog**:
- Automatic schema discovery
- Business glossary and tagging
- Data lineage tracking
- Search and discovery

**Data Quality**:
- Great Expectations or custom Dataflow jobs
- Automated validation rules
- Quality score tracking
- Anomaly detection

**Access Control**:
- IAM roles and policies
- Column-level security in BigQuery
- Data masking for PII
- Audit logging

## Ingestion Patterns

The platform provides 5 standard ingestion patterns to cover most data source types:

### Pattern 1: Batch File Ingestion
**Use Case**: Daily/hourly file drops (CSV, JSON, Parquet, etc.)

**Flow**:
```
External System → GCS Landing Bucket → Event Trigger → Cloud Function → Pub/Sub
```

**Implementation**:
- Cloud Function triggered on GCS object finalize
- Publishes file metadata to Pub/Sub
- Dataflow reads file and processes

**Configuration Example**:
```yaml
source_id: salesforce_exports
pattern: batch_file
schedule: "0 2 * * *"  # 2 AM daily
location: gs://landing-zone/salesforce/
format: csv
schema_file: schemas/salesforce_accounts.json
```

### Pattern 2: Streaming API Ingestion
**Use Case**: REST APIs, webhooks, SaaS platforms

**Flow**:
```
API Endpoint → Cloud Run Connector → Pub/Sub → Dataflow
```

**Implementation**:
- Cloud Run service with connector logic
- Polling (scheduled) or webhook receiver
- Publishes events to Pub/Sub

**Configuration Example**:
```yaml
source_id: stripe_payments
pattern: streaming_api
connector_type: rest_api
api_endpoint: https://api.stripe.com/v1/charges
auth_type: bearer_token
secret_name: stripe-api-key
poll_interval: 60s  # or webhook_path: /webhooks/stripe
```

### Pattern 3: Database CDC (Change Data Capture)
**Use Case**: Real-time replication from operational databases

**Flow**:
```
Source DB → Datastream → Pub/Sub → Dataflow → BigQuery
```

**Implementation**:
- Datastream captures database changes
- Publishes to Pub/Sub
- Dataflow applies transformations

**Configuration Example**:
```yaml
source_id: postgres_orders
pattern: database_cdc
connector_type: datastream
database_type: postgresql
connection_profile: projects/xxx/locations/us-central1/connectionProfiles/postgres-prod
tables:
  - orders
  - order_items
  - customers
```

### Pattern 4: Cloud-to-Cloud Transfer
**Use Case**: Data in AWS S3, Azure Blob, or other GCS buckets

**Flow**:
```
Source Cloud → Transfer Service → GCS → Event Trigger → Pub/Sub
```

**Implementation**:
- Storage Transfer Service for scheduled transfers
- GCS event triggers Pub/Sub on completion

**Configuration Example**:
```yaml
source_id: aws_data_lake
pattern: cloud_transfer
source_type: s3
source_bucket: my-aws-bucket
source_path: exports/
schedule: "0 */6 * * *"  # Every 6 hours
destination: gs://landing-zone/aws-imports/
```

### Pattern 5: Event Streaming (Pub/Sub Direct)
**Use Case**: High-volume event streams, IoT, clickstream

**Flow**:
```
Event Source → Pub/Sub → Dataflow → BigQuery/GCS
```

**Implementation**:
- Events published directly to Pub/Sub (via SDK)
- Dataflow windowed aggregations

**Configuration Example**:
```yaml
source_id: iot_sensors
pattern: event_streaming
pubsub_topic: projects/my-project/topics/iot-events
message_format: json
schema_file: schemas/iot_event.json
window_size: 60s
```

See `diagrams/ingestion-patterns.mmd` for visual representation.

## Data Architecture

### Schema Management

**Schema Registry**:
- JSON Schema definitions in `schemas/` directory
- Version controlled in Git
- Registered in Data Catalog
- Validation at ingestion time

**Schema Evolution**:
- Backward compatible changes (add fields)
- Schema versioning (v1, v2, etc.)
- Migration pipelines for breaking changes

### Data Partitioning Strategy

**Time-based Partitioning**:
- All tables partitioned by date/timestamp
- Reduces query costs
- Enables efficient pruning

**Clustering**:
- Up to 4 clustering columns
- Based on common filter patterns
- Example: `CLUSTER BY customer_id, product_category`

### Data Retention

| Zone | Hot (Standard) | Warm (Nearline) | Cold (Coldline) | Archive |
|------|----------------|-----------------|-----------------|---------|
| Bronze | 90 days | 1 year | 7 years | Never delete |
| Silver | 180 days | 2 years | 5 years | Recreatable |
| Gold | Always hot | N/A | N/A | Recreatable |

## Processing Pipelines

### Standard Pipeline Types

#### 1. Ingestion Pipeline
- **Trigger**: Pub/Sub message
- **Process**:
  1. Validate message format
  2. Write to Bronze (raw)
  3. Apply basic transformations
  4. Write to Silver (processed)
  5. Publish completion event
- **SLA**: 99.9% within 5 minutes

#### 2. Aggregation Pipeline
- **Trigger**: Schedule (daily, hourly)
- **Process**:
  1. Read from Silver
  2. Apply business logic
  3. Aggregate/denormalize
  4. Write to Gold
  5. Update materialized views
- **SLA**: Complete before 8 AM daily

#### 3. ML Feature Pipeline
- **Trigger**: Schedule or on-demand
- **Process**:
  1. Join multiple Gold tables
  2. Calculate features
  3. Write to Feature Store
  4. Version features
- **SLA**: 99% within 1 hour

### Pipeline Template

All pipelines extend a base template:

```python
class BasePipeline:
    - Error handling (DLQ)
    - Logging and monitoring
    - Retry logic
    - Schema validation
    - Data quality checks
    - Metadata tracking
```

## Serving Layer

### 1. Third-Party API

**Architecture**:
```
Client → API Gateway → Cloud Run (FastAPI) → BigQuery
```

**Features**:
- RESTful API (OpenAPI 3.0)
- OAuth 2.0 client credentials flow
- Query parameters for filtering/pagination
- Rate limiting (e.g., 1000 req/hour per client)
- Data export (JSON, CSV, Parquet)
- Webhook support for new data notifications

**Example Endpoints**:
```
GET /api/v1/customers?created_after=2024-01-01&limit=100
GET /api/v1/orders/{order_id}
POST /api/v1/webhooks/subscribe
```

### 2. Reporting Interface

**Architecture**:
```
BigQuery → Materialized Views → Looker → Embedded Dashboard
```

**Features**:
- Pre-aggregated summary tables
- Incremental refresh (not full reload)
- Drill-down capabilities
- Export to PDF/Excel
- Scheduled email reports

**Performance Optimization**:
- Materialized views for common queries
- BI Engine acceleration
- Query result caching
- Partition pruning

### 3. ML Feature Store

**Architecture**:
```
BigQuery (Gold) → Vertex AI Feature Store → Online/Offline Serving
```

**Features**:
- Feature versioning and lineage
- Point-in-time correctness
- Online serving (low latency)
- Offline serving (batch training)
- Feature monitoring and drift detection

**Integration**:
```python
# Training
features = feature_store.read_offline(
    entity_ids=['customer_123'],
    feature_ids=['ltv_90d', 'purchase_frequency'],
    timestamp=training_date
)

# Serving
features = feature_store.read_online(
    entity_id='customer_123',
    feature_ids=['ltv_90d', 'purchase_frequency']
)
```

## Extensibility Framework

### Onboarding a New Data Source (5-Minute Process)

**Step 1: Define Configuration (2 min)**
```bash
cp config/connectors/template.yaml config/connectors/my_new_source.yaml
# Edit my_new_source.yaml with source details
```

**Step 2: Define Schema (2 min)**
```bash
cp schemas/template.json schemas/my_new_source.json
# Edit schema definition
```

**Step 3: Deploy (1 min)**
```bash
./scripts/deploy-connector.sh my_new_source
```

The deployment script:
1. Validates configuration
2. Creates Pub/Sub topic
3. Deploys connector (Cloud Function/Run)
4. Creates Dataflow job from template
5. Registers schema in Data Catalog
6. Sets up monitoring dashboard
7. Configures alerts

### Connector Templates

**Available Templates**:
- `rest-api-polling`: Poll REST API on schedule
- `webhook-receiver`: Receive webhook POSTs
- `sftp-download`: Download files from SFTP
- `database-query`: Query database on schedule
- `cloud-storage-watch`: Watch GCS bucket for files
- `pubsub-direct`: Direct Pub/Sub publishing (SDK)

**Custom Connectors**:
- Extend base Docker image: `gcr.io/my-project/connector-base:latest`
- Implement `fetch()` and `transform()` methods
- Deploy to Cloud Run

### Pipeline Templates

**Beam Pipeline Templates**:
- `pubsub-to-bigquery`: Standard streaming ingestion
- `gcs-to-bigquery`: Batch file loading
- `bigquery-to-bigquery`: SQL transformations
- `pubsub-to-gcs`: Archive raw events

**Custom Transformations**:
```python
# Add custom transform to pipeline
from transforms import MyCustomTransform

pipeline_config['transforms'].append({
    'name': 'my_transform',
    'class': 'MyCustomTransform',
    'params': {...}
})
```

## Onboarding Process

### Detailed Walkthrough

**1. Requirements Gathering**
- Data source type (API, database, files, etc.)
- Update frequency (real-time, hourly, daily, etc.)
- Data volume (records/day, GB/day)
- Schema/data model
- Business purpose (which serving layer)

**2. Configuration**
```yaml
# config/connectors/example_source.yaml
source_id: example_source
display_name: "Example Data Source"
description: "Daily exports from Example SaaS platform"

# Ingestion configuration
ingestion:
  pattern: batch_file
  location: gs://landing-zone/example/
  schedule: "0 3 * * *"  # 3 AM daily
  format: json
  compression: gzip

# Schema
schema:
  file: schemas/example_source.json
  validation: strict
  evolution: backward_compatible

# Processing
processing:
  bronze_to_silver:
    - deduplication:
        key: [id, timestamp]
    - data_quality:
        rules:
          - field: email
            check: valid_email
          - field: amount
            check: positive_number

  silver_to_gold:
    - join:
        table: gold.customers
        on: customer_id
    - aggregate:
        group_by: [customer_id, date]
        metrics:
          - sum(amount) as total_amount
          - count(*) as transaction_count

# Serving
serving:
  third_party_api: true
  reporting: true
  ml_features: false

# Monitoring
monitoring:
  sla_minutes: 60
  alert_email: data-team@example.com
  metrics:
    - record_count
    - latency_p95
    - error_rate
```

**3. Schema Definition**
```json
{
  "source_id": "example_source",
  "version": "1.0",
  "fields": [
    {
      "name": "id",
      "type": "STRING",
      "mode": "REQUIRED",
      "description": "Unique transaction ID"
    },
    {
      "name": "customer_id",
      "type": "STRING",
      "mode": "REQUIRED",
      "description": "Customer identifier"
    },
    {
      "name": "amount",
      "type": "FLOAT64",
      "mode": "REQUIRED",
      "description": "Transaction amount in USD"
    },
    {
      "name": "timestamp",
      "type": "TIMESTAMP",
      "mode": "REQUIRED",
      "description": "Transaction timestamp (UTC)"
    }
  ]
}
```

**4. Deployment**
```bash
# Validate configuration
./scripts/validate-config.sh config/connectors/example_source.yaml

# Deploy (creates all infrastructure)
./scripts/deploy-connector.sh example_source

# Test ingestion
./scripts/test-connector.sh example_source

# Monitor
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=connector-example-source" --limit 50
```

**5. Verification**
- Check data in Bronze zone
- Verify processing to Silver
- Confirm Gold tables updated
- Test API endpoint (if applicable)
- Review dashboard

## Security & Governance

### Access Control

**IAM Strategy**:
- Service accounts for all components
- Least privilege principle
- No user credentials in code

**Data Access Tiers**:
1. **Bronze**: Data engineers only
2. **Silver**: Data engineers + analysts
3. **Gold**: All authenticated users (with row-level security)
4. **API**: External clients (OAuth 2.0)

**BigQuery Roles**:
- `roles/bigquery.dataViewer`: Read-only access
- `roles/bigquery.dataEditor`: Read + write (pipelines)
- `roles/bigquery.jobUser`: Run queries

### Data Security

**Encryption**:
- At rest: Customer-managed encryption keys (CMEK)
- In transit: TLS 1.2+
- Application-layer: Tokenization for PII

**PII Handling**:
- DLP API for automatic detection
- Masking in non-production environments
- Separate BigQuery dataset for PII
- Column-level access control

**Compliance**:
- Audit logs enabled (Cloud Audit Logs)
- Data retention policies
- Data residency (regional resources)
- GDPR/CCPA data deletion workflows

### Data Lineage

**Automated Tracking**:
- Data Catalog captures lineage
- Custom tags for business context
- Source → Bronze → Silver → Gold → Serving

**Lineage Graph Example**:
```
salesforce_api → bronze.salesforce_raw → silver.salesforce_accounts → gold.customer_360 → API /customers
```

## Monitoring & Operations

### Observability Stack

**Metrics** (Cloud Monitoring):
- Pipeline execution time
- Record counts (input vs. output)
- Error rates
- Data freshness (lag from source)
- Cost per pipeline

**Logging** (Cloud Logging):
- Structured JSON logs
- Correlation IDs across components
- Log-based metrics

**Tracing** (Cloud Trace):
- End-to-end request tracing
- Dataflow job profiling

**Alerting**:
```yaml
alerts:
  - name: Pipeline Failure
    condition: error_rate > 5%
    notification: data-team@example.com

  - name: Data Freshness SLA
    condition: data_age > 2 hours
    notification: pagerduty

  - name: Cost Spike
    condition: daily_cost > $500
    notification: finance-team@example.com
```

### Standard Dashboards

**1. Platform Health Dashboard**
- Active connectors
- Pipeline success rate
- Data volume trends
- Error rates by source

**2. Data Freshness Dashboard**
- Last update time per source
- SLA compliance
- Processing lag

**3. Cost Dashboard**
- Cost per source
- Storage costs (by zone)
- Compute costs (Dataflow)
- Serving costs (API, BigQuery)

### Runbooks

**Common Scenarios**:
1. Pipeline failure → Check DLQ, replay messages
2. Schema change → Deploy new version, backfill
3. Data quality issue → Quarantine bad data, alert stakeholders
4. Performance degradation → Scale Dataflow workers, optimize queries

## Cost Optimization

### Storage Optimization

**Lifecycle Policies**:
```
Bronze (GCS):
  - 0-90 days: Standard
  - 91-365 days: Nearline
  - 365+ days: Coldline

Silver (GCS):
  - 0-180 days: Standard
  - 180+ days: Nearline
```

**BigQuery Optimization**:
- Partitioning: Reduce scanned data
- Clustering: Improve query performance
- Materialized views: Cache expensive queries
- BI Engine: In-memory acceleration
- Slots: Flat-rate pricing for predictable workloads

### Compute Optimization

**Dataflow**:
- Flexible Resource Scheduling (Flex templates)
- Use Streaming Engine (separate compute/storage)
- Autoscaling policies
- Spot/preemptible workers for batch

**Cloud Run/Functions**:
- Minimum instances = 0 (scale to zero)
- Maximum instances based on load testing
- CPU/memory right-sizing

### Query Optimization

**Best Practices**:
- Avoid `SELECT *`
- Use partitioning filters
- Denormalize for common queries
- Cache results for 24 hours
- Use approximate aggregations where acceptable

**Cost Monitoring**:
```sql
-- Daily cost by user
SELECT
  user_email,
  SUM(total_bytes_billed) / POW(10, 12) * 5 AS estimated_cost_usd
FROM `region-us`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
WHERE creation_time >= CURRENT_DATE()
GROUP BY user_email
ORDER BY estimated_cost_usd DESC;
```

## Implementation Roadmap

### Phase 1: Foundation (Weeks 1-4)
- Set up GCP project and organization policies
- Deploy core infrastructure (Terraform)
- Implement first ingestion pattern (batch files)
- Build Bronze → Silver → Gold pipeline
- Set up monitoring and alerting

### Phase 2: Extensibility (Weeks 5-8)
- Implement all 5 ingestion patterns
- Build connector templates
- Create deployment automation
- Develop schema registry
- Build self-service portal

### Phase 3: Serving Layers (Weeks 9-12)
- Build third-party API
- Implement reporting dashboards
- Set up ML feature store
- Create documentation portal
- Conduct user training

### Phase 4: Production Hardening (Weeks 13-16)
- Load testing and optimization
- Security review and penetration testing
- Disaster recovery testing
- Cost optimization
- Runbook development

## Appendix

### A. Technology Alternatives Considered

| Requirement | Chosen | Alternatives Considered | Reason |
|-------------|--------|------------------------|---------|
| Stream Processing | Dataflow | Spark on Dataproc | Fully managed, auto-scaling |
| Orchestration | Cloud Composer | Cloud Workflows | Complex DAGs, existing Airflow knowledge |
| API Gateway | Cloud Endpoints | Apigee | Cost-effective for data APIs |
| Data Warehouse | BigQuery | Snowflake, Redshift | Native GCP, serverless, cost-effective |

### B. Capacity Planning

**Assumptions**:
- 100 data sources
- 10 GB/day per source (1 TB/day total)
- 1 billion records/day
- 100 API clients
- 10,000 API requests/day

**Estimated Monthly Costs**:
- Storage (GCS): $500
- BigQuery storage: $2,000
- BigQuery compute: $3,000
- Dataflow: $5,000
- Cloud Run/Functions: $500
- Networking: $1,000
- **Total: ~$12,000/month**

### C. Disaster Recovery

**RTO/RPO**:
- Bronze zone: RPO = 1 hour, RTO = 4 hours
- Silver/Gold: RPO = 24 hours, RTO = 8 hours (recreatable)
- API: RTO = 1 hour (multi-region)

**Backup Strategy**:
- Bronze: Cross-region replication
- Silver/Gold: Export to GCS weekly
- Configs: Version controlled in Git
- Terraform state: GCS backend with versioning

### D. Reference Architecture Diagram

See `diagrams/overall-architecture.mmd` for the complete visual architecture.

### E. Glossary

- **Bronze Zone**: Raw data, immutable
- **Silver Zone**: Cleaned, validated data
- **Gold Zone**: Business-ready, curated data
- **Connector**: Component that ingests data from a source
- **Pipeline**: Data processing workflow
- **SLA**: Service Level Agreement (uptime, latency targets)
- **DLQ**: Dead Letter Queue (failed messages)
- **CDC**: Change Data Capture (database replication)

## Conclusion

This architecture provides a robust, scalable, and extensible data platform that can rapidly onboard new data sources while serving multiple downstream use cases. The configuration-driven approach ensures that data engineers can add sources in minutes, not days, while maintaining high standards for data quality, security, and observability.

**Next Steps**:
1. Review and approve architecture
2. Set up GCP project and billing
3. Deploy Phase 1 infrastructure
4. Onboard first pilot data source
5. Iterate based on feedback

---

**Document Version**: 1.0
**Last Updated**: 2025-11-14
**Authors**: Software Architecture Team
**Reviewers**: Data Engineering, Platform Engineering, Security
