# Climate Data Platform

A centralized climate data integration platform built with Rust and Google BigQuery, designed to aggregate multiple public climate data sources for machine learning and analysis.

## Overview

This platform integrates 10+ free and public climate data sources into a unified BigQuery data warehouse, enabling:
- Centralized access to global climate data
- ML-ready datasets for climate modeling
- Historical and real-time weather data analysis
- Multi-source data correlation and validation

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Data Sources                          │
│  NOAA │ NASA │ ERA5 │ OpenWeather │ World Bank │ ...   │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
          ┌──────────────────────┐
          │  Rust Ingestion      │
          │  Service             │
          │  - API Clients       │
          │  - ETL Pipelines     │
          │  - Validation        │
          └──────────┬───────────┘
                     │
                     ▼
          ┌──────────────────────┐
          │   Google BigQuery    │
          │   ├── raw/           │
          │   ├── staging/       │
          │   └── analytics/     │
          └──────────┬───────────┘
                     │
                     ▼
          ┌──────────────────────┐
          │   ML & Analytics     │
          └──────────────────────┘
```

## Data Sources

The platform integrates the following public climate datasets:

1. **NOAA Climate Data Online (CDO)** - Global weather observations
2. **NASA POWER API** - Solar and meteorological data
3. **ERA5 Climate Reanalysis** - ECMWF atmospheric reanalysis
4. **OpenWeather** - Real-time weather data
5. **World Bank Climate Data** - Climate projections and indicators
6. **NOAA GHCN** - Historical climatology network
7. **ESA Climate Change Initiative** - Satellite climate variables
8. **NOAA Sea Level Rise** - Coastal sea level data
9. **NOAA CO2 Data** - Greenhouse gas measurements
10. **OpenAQ** - Global air quality data

See [docs/DATA_INTEGRATION_PLAN.md](docs/DATA_INTEGRATION_PLAN.md) for detailed information.

## Project Structure

```
climate-data-platform/
├── Cargo.toml                    # Rust dependencies
├── src/
│   ├── main.rs                   # Application entry point
│   ├── datasources/              # Data source connectors
│   │   ├── noaa_cdo.rs
│   │   ├── nasa_power.rs
│   │   └── ...
│   ├── bigquery/                 # BigQuery integration
│   │   ├── client.rs
│   │   ├── schema.rs
│   │   └── loader.rs
│   ├── models/                   # Data models
│   └── utils/                    # Utilities
├── schemas/                      # BigQuery table schemas
├── docs/                         # Documentation
│   └── DATA_INTEGRATION_PLAN.md  # Master integration plan
└── README.md
```

## Getting Started

### Prerequisites

- Rust 1.70+ (install from https://rustup.rs/)
- Google Cloud Platform account
- BigQuery API enabled
- API keys for data sources (see setup guide)

### Installation

1. Clone the repository:
```bash
cd climate
```

2. Install dependencies:
```bash
cargo build
```

3. Configure environment:
```bash
cp .env.example .env
# Edit .env with your API keys and GCP credentials
```

4. Run the application:
```bash
cargo run
```

### Configuration

Create a `.env` file with the following variables:

```env
# Google Cloud
GCP_PROJECT_ID=your-project-id
BIGQUERY_DATASET=climate_data_platform
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account-key.json

# NOAA CDO
NOAA_CDO_API_KEY=your-noaa-key

# OpenWeather
OPENWEATHER_API_KEY=your-openweather-key

# Copernicus CDS (ERA5)
CDS_API_KEY=your-cds-key
CDS_API_URL=https://cds.climate.copernicus.eu/api/v2

# OpenAQ
OPENAQ_API_KEY=your-openaq-key

# Logging
RUST_LOG=info
```

## Development

### Running Tests

```bash
cargo test
```

### Running a Specific Data Source

```bash
cargo run -- --source noaa_cdo --date 2025-01-01
```

### Building for Production

```bash
cargo build --release
```

## BigQuery Schema

The platform uses a three-tier data structure:

- **raw/**: Raw data as ingested from sources
- **staging/**: Cleaned and transformed data
- **analytics/**: ML-ready aggregated datasets

See [docs/BIGQUERY_SCHEMAS.md](docs/BIGQUERY_SCHEMAS.md) for detailed schema documentation.

## Integration Timeline

- **Phase 1** (Weeks 1-2): Infrastructure setup
- **Phase 2** (Weeks 3-10): Core data sources (NOAA, NASA, ERA5, OpenWeather)
- **Phase 3** (Weeks 11-18): Extended sources (World Bank, GHCN, ESA, Sea Level, CO2)
- **Phase 4** (Weeks 19-20): Real-time data (OpenAQ)
- **Phase 5** (Weeks 21-24): Data quality and transformation
- **Phase 6** (Weeks 25-28): Analytics and ML preparation

## API Keys Setup

### NOAA CDO
1. Visit https://www.ncdc.noaa.gov/cdo-web/token
2. Request a free API token
3. Add to `.env` as `NOAA_CDO_API_KEY`

### NASA POWER
- No API key required

### Copernicus CDS (ERA5)
1. Register at https://cds.climate.copernicus.eu/
2. Get API key from user profile
3. Add to `.env`

### OpenWeather
1. Sign up at https://openweathermap.org/api
2. Get free API key
3. Add to `.env`

### OpenAQ
1. Register at https://openaq.org/
2. Get API key
3. Add to `.env`

## Contributing

This is an experimental project. Contributions are welcome!

## License

MIT License - see LICENSE file for details

## Resources

- [Data Integration Plan](docs/DATA_INTEGRATION_PLAN.md)
- [NOAA CDO Documentation](https://www.ncdc.noaa.gov/cdo-web/webservices/v2)
- [NASA POWER Documentation](https://power.larc.nasa.gov/docs/)
- [Copernicus CDS Documentation](https://cds.climate.copernicus.eu/api-how-to)
- [BigQuery Documentation](https://cloud.google.com/bigquery/docs)

## Support

For questions or issues, please refer to the documentation in the `docs/` directory.

---

**Status**: Initial Setup Complete
**Last Updated**: 2025-11-14
