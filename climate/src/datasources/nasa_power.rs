// NASA POWER API integration
// Documentation: https://power.larc.nasa.gov/docs/

use anyhow::Result;
use async_trait::async_trait;
use reqwest::Client;

use super::{ClimateRecord, DataSource};

const NASA_POWER_BASE_URL: &str = "https://power.larc.nasa.gov/api/temporal/daily/point";

pub struct NasaPowerClient {
    client: Client,
}

impl NasaPowerClient {
    pub fn new() -> Result<Self> {
        Ok(Self {
            client: Client::new(),
        })
    }
}

#[async_trait]
impl DataSource for NasaPowerClient {
    async fn fetch_data(&self, start_date: &str, end_date: &str) -> Result<Vec<ClimateRecord>> {
        // TODO: Implement NASA POWER API data fetching
        log::info!(
            "Fetching NASA POWER data from {} to {}",
            start_date,
            end_date
        );

        Ok(vec![])
    }

    fn source_name(&self) -> &str {
        "nasa_power"
    }
}
