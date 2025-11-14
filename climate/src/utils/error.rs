// Custom error types for the climate data platform

use thiserror::Error;

#[derive(Error, Debug)]
pub enum ClimateError {
    #[error("API error: {0}")]
    ApiError(String),

    #[error("Data validation error: {0}")]
    ValidationError(String),

    #[error("BigQuery error: {0}")]
    BigQueryError(String),

    #[error("Configuration error: {0}")]
    ConfigError(String),

    #[error("IO error: {0}")]
    IoError(#[from] std::io::Error),

    #[error("Network error: {0}")]
    NetworkError(#[from] reqwest::Error),

    #[error("JSON error: {0}")]
    JsonError(#[from] serde_json::Error),
}
