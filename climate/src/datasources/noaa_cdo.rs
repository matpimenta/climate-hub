// NOAA Climate Data Online (CDO) API integration
// Documentation: https://www.ncdc.noaa.gov/cdo-web/webservices/v2

use anyhow::{Context, Result};
use async_trait::async_trait;
use reqwest::Client;
use serde::{Deserialize, Serialize};
use std::env;

use super::{ClimateRecord, DataSource};

const NOAA_CDO_BASE_URL: &str = "https://www.ncdc.noaa.gov/cdo-web/api/v2";

pub struct NoaaCdoClient {
    client: Client,
    api_key: String,
}

#[derive(Debug, Deserialize)]
struct NoaaResponse {
    results: Vec<NoaaRecord>,
}

#[derive(Debug, Deserialize)]
struct NoaaRecord {
    date: String,
    datatype: String,
    station: String,
    value: f64,
}

impl NoaaCdoClient {
    pub fn new() -> Result<Self> {
        let api_key = env::var("NOAA_CDO_API_KEY")
            .context("NOAA_CDO_API_KEY not found in environment")?;

        Ok(Self {
            client: Client::new(),
            api_key,
        })
    }
}

#[async_trait]
impl DataSource for NoaaCdoClient {
    async fn fetch_data(&self, start_date: &str, end_date: &str) -> Result<Vec<ClimateRecord>> {
        // TODO: Implement NOAA CDO API data fetching
        // This is a stub implementation
        log::info!(
            "Fetching NOAA CDO data from {} to {}",
            start_date,
            end_date
        );

        Ok(vec![])
    }

    fn source_name(&self) -> &str {
        "noaa_cdo"
    }
}
