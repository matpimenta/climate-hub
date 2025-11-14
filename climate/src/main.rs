use anyhow::Result;
use dotenv::dotenv;
use log::info;

mod bigquery;
mod datasources;
mod models;
mod utils;

#[tokio::main]
async fn main() -> Result<()> {
    // Load environment variables
    dotenv().ok();

    // Initialize logger
    env_logger::init();

    info!("Climate Data Platform starting...");
    info!("Version: {}", env!("CARGO_PKG_VERSION"));

    // TODO: Implement CLI argument parsing
    // TODO: Implement data source orchestration
    // TODO: Implement BigQuery connection

    info!("Climate Data Platform initialized successfully");

    Ok(())
}
