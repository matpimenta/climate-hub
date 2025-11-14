// Data source modules for climate data ingestion

pub mod noaa_cdo;
pub mod nasa_power;
// pub mod era5;
// pub mod openweather;
// pub mod worldbank;
// pub mod ghcn;
// pub mod esa_cci;
// pub mod noaa_sea_level;
// pub mod noaa_co2;
// pub mod openaq;

use anyhow::Result;
use async_trait::async_trait;
use serde::{Deserialize, Serialize};

#[async_trait]
pub trait DataSource {
    async fn fetch_data(&self, start_date: &str, end_date: &str) -> Result<Vec<ClimateRecord>>;
    fn source_name(&self) -> &str;
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ClimateRecord {
    pub source_id: String,
    pub timestamp: String,
    pub latitude: f64,
    pub longitude: f64,
    pub location_name: Option<String>,
    pub data: serde_json::Value,
}
