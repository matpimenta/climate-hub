// BigQuery client for connecting to Google BigQuery

use anyhow::{Context, Result};
use gcp_bigquery_client::Client;
use std::env;

pub struct BigQueryClient {
    project_id: String,
    dataset_id: String,
}

impl BigQueryClient {
    pub async fn new() -> Result<Self> {
        let project_id =
            env::var("GCP_PROJECT_ID").context("GCP_PROJECT_ID not found in environment")?;

        let dataset_id = env::var("BIGQUERY_DATASET")
            .context("BIGQUERY_DATASET not found in environment")?;

        Ok(Self {
            project_id,
            dataset_id,
        })
    }

    pub fn project_id(&self) -> &str {
        &self.project_id
    }

    pub fn dataset_id(&self) -> &str {
        &self.dataset_id
    }

    // TODO: Add methods for BigQuery operations
    // - create_dataset
    // - create_table
    // - insert_rows
    // - query
}
