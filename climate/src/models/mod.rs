// Data models for climate data

use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WeatherObservation {
    pub observation_id: String,
    pub source_id: String,
    pub timestamp: String,
    pub latitude: f64,
    pub longitude: f64,
    pub location_name: Option<String>,
    pub temperature_celsius: Option<f64>,
    pub precipitation_mm: Option<f64>,
    pub wind_speed_ms: Option<f64>,
    pub humidity_percent: Option<f64>,
    pub pressure_hpa: Option<f64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ClimateProjection {
    pub projection_id: String,
    pub model: String,
    pub scenario: String,
    pub year: i32,
    pub region: String,
    pub variable: String,
    pub value: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AirQualityMeasurement {
    pub measurement_id: String,
    pub timestamp: String,
    pub latitude: f64,
    pub longitude: f64,
    pub location_name: Option<String>,
    pub pm25: Option<f64>,
    pub pm10: Option<f64>,
    pub o3: Option<f64>,
    pub no2: Option<f64>,
    pub so2: Option<f64>,
    pub co: Option<f64>,
}
