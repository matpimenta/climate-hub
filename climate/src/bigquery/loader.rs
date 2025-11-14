// Data loader for BigQuery

use anyhow::Result;

use crate::datasources::ClimateRecord;

pub struct DataLoader {
    // TODO: Add BigQuery client reference
}

impl DataLoader {
    pub fn new() -> Self {
        Self {}
    }

    pub async fn load_records(&self, records: Vec<ClimateRecord>) -> Result<()> {
        // TODO: Implement batch loading to BigQuery
        log::info!("Loading {} records to BigQuery", records.len());
        Ok(())
    }

    pub async fn load_streaming(&self, record: ClimateRecord) -> Result<()> {
        // TODO: Implement streaming insert to BigQuery
        log::info!("Streaming record to BigQuery");
        Ok(())
    }
}
