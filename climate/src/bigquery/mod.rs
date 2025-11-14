// BigQuery integration module

pub mod client;
pub mod loader;
pub mod schema;

pub use client::BigQueryClient;
pub use loader::DataLoader;
pub use schema::SchemaManager;
