# Climate Data Sources - Authoritative Public Datasets

This document catalogs high-quality public climate datasets from authoritative sources suitable for integration into data platforms. All datasets listed are publicly accessible, well-documented, and maintained by recognized scientific institutions.

**Last Updated:** 2025-11-14

---

## Dataset 1: NASA GISTEMP v4 - Global Surface Temperature

### Overview
NASA's Goddard Institute for Space Studies Surface Temperature Analysis (GISTEMP v4) provides global surface temperature anomaly estimates combining land-surface air and sea-surface water temperature anomalies.

### Source Organization
**NASA Goddard Institute for Space Studies (GISS)**

### Description
Monthly global-mean temperature anomalies from 1880 to present, updated monthly around the 10th of each month. Data combines NOAA GHCN-M v4 (land) and ERSST v5 (ocean) observations. Provides global, hemispheric, and zonal mean temperature anomalies relative to 1951-1980 baseline.

### Data Format
- **Primary Formats**: CSV, TXT, NetCDF
- **Structure**: Time series data with monthly, seasonal, and annual aggregations
- **Grid Options**: 2° x 2° latitude-longitude grid

### Access Method
- **Direct Download**: HTTP download from data.giss.nasa.gov
- **Bulk Download**: Available via FTP
- **API**: Limited API access through NASA API Portal (requires free API key)

### URL/Endpoint
- **Landing Page**: https://data.giss.nasa.gov/gistemp/
- **Direct Data**: https://data.giss.nasa.gov/gistemp/tabledata_v4/
- **Global Monthly CSV**: https://data.giss.nasa.gov/gistemp/tabledata_v4/GLB.Ts+dSST.csv

### Update Frequency
**Monthly** - Updated approximately on the 10th of each month with previous month's data

### Key Fields/Variables
- `Year`: Calendar year
- `Jan-Dec`: Monthly temperature anomalies (°C) relative to 1951-1980 baseline
- `J-D`: January-December annual mean
- `D-N`: December-November annual mean
- `DJF, MAM, JJA, SON`: Seasonal means (Winter, Spring, Summer, Fall)

### Authentication Requirements
**None** for direct downloads (public domain U.S. government data)
**Free API Key** required for NASA API Portal access

### License/Usage Terms
**Public Domain** - U.S. government data, no restrictions on use or redistribution
**Attribution**: Recommended to cite as "GISTEMP Team, 2024: GISS Surface Temperature Analysis (GISTEMP), version 4. NASA Goddard Institute for Space Studies."

### Recommended Use Cases
- Historical global temperature trend analysis
- Climate change visualization dashboards
- Temperature anomaly tracking and forecasting
- Cross-validation with other temperature datasets
- Educational climate data platforms

### Integration Notes
- **Complexity**: LOW - Simple CSV format, easy to parse
- **Storage**: Minimal (~1 MB for global monthly data)
- **Processing**: Direct load to BigQuery or similar data warehouse
- **Partitioning**: Recommended by year or decade

---

## Dataset 2: NOAA Climate Data Online (CDO) API

### Overview
NOAA's Climate Data Online provides comprehensive access to weather and climate data from multiple NOAA datasets including GHCND (daily summaries), normals, precipitation, and more.

### Source Organization
**NOAA National Centers for Environmental Information (NCEI)**

### Description
RESTful web services providing programmatic access to NOAA's archive of global historical weather and climate data. Includes daily summaries, monthly summaries, normals, and station metadata for thousands of weather stations worldwide.

### Data Format
- **Primary Format**: JSON (all responses)
- **Export Options**: CSV available for certain endpoints
- **Structure**: RESTful API with pagination support

### Access Method
- **RESTful API**: HTTPS requests with JSON responses
- **Web Interface**: Available at ncdc.noaa.gov/cdo-web
- **Bulk Download**: FTP available for large datasets

### URL/Endpoint
- **Base API URL**: `https://www.ncei.noaa.gov/cdo-web/api/v2/`
- **API Documentation**: https://www.ncdc.noaa.gov/cdo-web/webservices/v2
- **Token Request**: https://www.ncdc.noaa.gov/cdo-web/token

**Available Endpoints:**
- `/datasets` - Available dataset collections
- `/datacategories` - Data type groupings
- `/datatypes` - Specific measurement types
- `/locations` - Geographic entities
- `/stations` - Weather station metadata
- `/data` - Actual observations

### Update Frequency
**Daily** - Most datasets updated daily with 1-2 day lag

### Key Fields/Variables
**Common Parameters:**
- `datasetid`: Dataset identifier (e.g., GHCND, GSOM, GSOY)
- `datatypeid`: Data type (e.g., TMAX, TMIN, PRCP, SNOW)
- `locationid`: Geographic location (ZIP, FIPS, CITY, STATE)
- `stationid`: Weather station identifier
- `startdate/enddate`: Date range (ISO format YYYY-MM-DD)
- `units`: standard or metric

**Response Fields:**
- `date`: Observation date/time
- `datatype`: Type of measurement
- `station`: Station identifier
- `attributes`: Quality flags and metadata
- `value`: Measured value

### Authentication Requirements
**Required** - Free API token
- Register at NOAA CDO Web Services
- Include token in request header: `token: YOUR_TOKEN`
- **Rate Limits**: 5 requests/second, 10,000 requests/day per token

### License/Usage Terms
**Public Domain** - U.S. government data, freely available
**Citation**: "NOAA National Centers for Environmental Information. Climate Data Online."

### Recommended Use Cases
- Historical weather data analysis by location
- Climate normals and extremes tracking
- Multi-station precipitation analysis
- Temperature and precipitation time series
- Weather station data aggregation

### Integration Notes
- **Complexity**: MEDIUM - Requires pagination handling, multiple API calls for comprehensive data
- **Example API Call**:
  ```
  GET https://www.ncei.noaa.gov/cdo-web/api/v2/data?datasetid=GHCND&locationid=ZIP:28801&startdate=2023-01-01&enddate=2023-12-31&datatypeid=TMAX&units=metric&limit=1000
  Headers: token: YOUR_TOKEN_HERE
  ```
- **Pagination**: Use `offset` and `limit` parameters (max 1000 per request)
- **Date Ranges**: Annual/monthly data limited to 10-year range; other data limited to 1-year range

---

## Dataset 3: Our World in Data - CO2 and Greenhouse Gas Emissions

### Overview
Comprehensive, curated dataset on CO2 and greenhouse gas emissions combining data from multiple authoritative sources including the Global Carbon Project, Energy Institute, and national statistical agencies.

### Source Organization
**Our World in Data (Oxford Martin School, University of Oxford)**

### Description
Annual CO2 emissions data by country from 1750 to present, including fossil fuel emissions, land-use change, per capita metrics, cumulative emissions, consumption-based emissions, and other greenhouse gases (CH4, N2O). Includes energy mix and carbon intensity indicators.

### Data Format
- **CSV**: Single file with one row per country-year
- **XLSX**: Excel workbook format
- **JSON**: Nested structure organized by country
- **Codebook**: Separate CSV documenting all variables

### Access Method
- **Direct HTTP Download**: From DigitalOcean Spaces CDN
- **GitHub Repository**: Version-controlled data at github.com/owid/co2-data
- **GitHub API**: Programmatic access via GitHub's REST API
- **Web Interface**: Interactive explorer at ourworldindata.org

### URL/Endpoint
- **CSV**: https://nyc3.digitaloceanspaces.com/owid-public/data/co2/owid-co2-data.csv
- **XLSX**: https://nyc3.digitaloceanspaces.com/owid-public/data/co2/owid-co2-data.xlsx
- **JSON**: https://nyc3.digitaloceanspaces.com/owid-public/data/co2/owid-co2-data.json
- **GitHub**: https://github.com/owid/co2-data
- **Codebook**: https://github.com/owid/co2-data/blob/master/owid-co2-codebook.csv

### Update Frequency
**Annually** - Updated in November/December with latest Global Carbon Budget release

### Key Fields/Variables
**Emissions Metrics:**
- `co2`: Annual total CO2 emissions (million tonnes)
- `co2_per_capita`: Per capita CO2 emissions (tonnes/person)
- `cumulative_co2`: Cumulative CO2 since 1750
- `consumption_co2`: Consumption-based CO2 emissions
- `co2_growth_prct`: Annual percentage growth

**Emissions by Source:**
- `coal_co2`, `oil_co2`, `gas_co2`, `flaring_co2`
- `cement_co2`, `other_industry_co2`
- `land_use_change_co2`

**Other Greenhouse Gases:**
- `methane`, `nitrous_oxide`
- `total_ghg` (CO2 equivalents)

**Context Variables:**
- `population`, `gdp`
- `primary_energy_consumption`
- `energy_per_capita`, `energy_per_gdp`

**Metadata:**
- `country`, `year`, `iso_code`

### Authentication Requirements
**None** - Open access, no authentication required

### License/Usage Terms
**Creative Commons BY 4.0** - Free to use with attribution
**Citation Required**: "Our World in Data" and underlying source datasets
**Commercial Use**: Permitted with attribution

### Recommended Use Cases
- National and global emissions tracking
- Per capita and cumulative emissions analysis
- Emissions vs GDP/population correlations
- Historical emissions trend visualization
- Carbon budget tracking and forecasting
- Sectoral emissions breakdown

### Integration Notes
- **Complexity**: LOW - Single CSV file, well-structured
- **File Size**: ~15 MB (CSV)
- **Automation**: Can schedule downloads via cron/Cloud Scheduler
- **GitHub Integration**: Use GitHub API for version tracking
- **Example Download**:
  ```bash
  curl -o owid-co2-data.csv https://nyc3.digitaloceanspaces.com/owid-public/data/co2/owid-co2-data.csv
  ```

---

## Dataset 4: Copernicus Climate Data Store - ERA5 Reanalysis

### Overview
High-resolution global atmospheric reanalysis combining model data and observations, providing comprehensive climate variables from 1940 to near-present with sub-daily temporal resolution.

### Source Organization
**European Centre for Medium-Range Weather Forecasts (ECMWF) / Copernicus Climate Change Service (C3S)**

### Description
ERA5 is the fifth generation ECMWF reanalysis, providing hourly estimates of atmospheric, land, and oceanic climate variables at high spatial resolution. Covers global atmosphere with extensive vertical levels and surface parameters including temperature, precipitation, wind, pressure, humidity, and more.

### Data Format
- **Primary Format**: NetCDF (GRIB also available)
- **Structure**: Multi-dimensional arrays (time, latitude, longitude, pressure levels)
- **Grid Resolution**: 0.25° x 0.25° (~31 km)
- **Temporal Resolution**: Hourly, with monthly mean products

### Access Method
- **CDS API**: Python-based cdsapi client
- **Web Interface**: Interactive download form at CDS portal
- **Subsetting**: Spatial, temporal, and variable subsetting supported

### URL/Endpoint
- **CDS Portal**: https://cds.climate.copernicus.eu/
- **ERA5 Monthly**: https://cds.climate.copernicus.eu/cdsapp#!/dataset/reanalysis-era5-single-levels-monthly-means
- **Python Package**: `pip install cdsapi`
- **GitHub**: https://github.com/ecmwf/cdsapi

### Update Frequency
**Daily** - Typically 5-day lag for near-real-time data
**Monthly aggregations** - Updated within 1-2 months

### Key Fields/Variables
**Atmospheric Variables:**
- `2m_temperature`: 2-meter air temperature (K)
- `total_precipitation`: Total precipitation (m)
- `10m_u_component_of_wind`, `10m_v_component_of_wind`: Wind components (m/s)
- `sea_level_pressure`: Mean sea level pressure (Pa)
- `surface_pressure`: Surface pressure (Pa)

**Surface Variables:**
- `sea_surface_temperature`: SST (K)
- `snow_depth`: Snow depth (m)
- `soil_temperature_level_1`: Top soil temperature (K)

**Radiation:**
- `surface_solar_radiation_downwards`
- `surface_thermal_radiation_downwards`

**Hundreds more variables** available across atmosphere, ocean, land, and radiation categories

### Authentication Requirements
**Required** - Free CDS account
- Register at https://cds.climate.copernicus.eu/user/register
- Generate Personal Access Token from profile
- Save to `~/.cdsapirc` configuration file
- Agree to dataset Terms of Use before first download

### License/Usage Terms
**Copernicus License** - Free for all users
**Attribution Required**: "Generated using Copernicus Climate Change Service information"
**Commercial Use**: Permitted with attribution
**No Warranties**: Data provided "as is"

### Recommended Use Cases
- High-resolution climate reanalysis
- Weather pattern analysis
- Climate model validation
- Extreme event studies
- Renewable energy potential assessment
- Agricultural and hydrological modeling

### Integration Notes
- **Complexity**: HIGH - Large data volumes, NetCDF processing required, subsetting essential
- **Storage**: Can be very large (TBs for full global hourly data)
- **Processing**: Requires NetCDF libraries (xarray, netCDF4), consider subsetting by region/time
- **Example Python Code**:
  ```python
  import cdsapi

  client = cdsapi.Client()

  client.retrieve(
      'reanalysis-era5-single-levels-monthly-means',
      {
          'product_type': 'monthly_averaged_reanalysis',
          'variable': '2m_temperature',
          'year': ['2020', '2021', '2022'],
          'month': ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12'],
          'time': '00:00',
          'area': [90, -180, -90, 180],  # Global
          'format': 'netcdf',
      },
      'era5_temperature.nc'
  )
  ```
- **Best Practice**: Start with monthly means, subset by region, convert to Parquet for analytics

---

## Dataset 5: Global Warming API - Greenhouse Gas Concentrations

### Overview
Simple REST API providing time series data on atmospheric greenhouse gas concentrations (CO2, CH4, N2O) and global temperature anomalies, sourced from NASA and NOAA observations.

### Source Organization
**Global Warming Organization (Community Project)**
Data Sources: NASA GISTEMP, NOAA Global Monitoring Laboratory

### Description
Free JSON API providing monthly and daily measurements of key climate indicators: global temperature anomalies from 1880, atmospheric CO2 concentrations (last 10 years daily), methane from 1983, and nitrous oxide from 2001. Simple endpoint structure with no authentication required.

### Data Format
- **Format**: JSON only
- **Structure**: Array of objects with time and value pairs
- **Encoding**: UTF-8

### Access Method
- **REST API**: Direct HTTP GET requests
- **No SDK Required**: Standard HTTP client libraries work
- **CORS Enabled**: Can be called from browser JavaScript

### URL/Endpoint
- **Base URL**: https://global-warming.org/api/
- **Temperature API**: https://global-warming.org/api/temperature-api
- **CO2 API**: https://global-warming.org/api/co2-api
- **Methane API**: https://global-warming.org/api/methane-api
- **Nitrous Oxide API**: https://global-warming.org/api/nitrous-oxide-api

### Update Frequency
- **Temperature**: Monthly (follows NASA GISTEMP schedule)
- **CO2**: Quasi-daily updates
- **Methane**: Monthly
- **Nitrous Oxide**: Monthly

### Key Fields/Variables
**Temperature API Response:**
```json
{
  "result": [
    {
      "time": "1880.04",
      "station": "GISTEMP",
      "land": "-0.41"
    }
  ]
}
```
- `time`: Year.month decimal format
- `station`: Data source identifier
- `land`: Temperature anomaly in Celsius

**CO2 API Response:**
```json
{
  "co2": [
    {
      "year": "2023",
      "month": "1",
      "day": "15",
      "cycle": "415.23",
      "trend": "416.12"
    }
  ]
}
```
- `year`, `month`, `day`: Date components
- `cycle`: CO2 concentration with seasonal cycle (ppm)
- `trend`: Deseasonalized trend (ppm)

**Methane API Response:**
- `date`: YYYY-MM format
- `average`: Atmospheric CH4 in ppb
- `trend`: Deseasonalized trend in ppb

**Nitrous Oxide API Response:**
- `date`: YYYY-MM format
- `average`: Atmospheric N2O in ppb
- `trend`: Deseasonalized trend in ppb

### Authentication Requirements
**None** - Completely open API, no authentication or API keys required

### License/Usage Terms
**Not explicitly stated** - Appears to be freely available for public use
**Data Sources**: NASA and NOAA (public domain data)
**Recommended**: Verify usage terms on website, attribute data sources

### Recommended Use Cases
- Real-time greenhouse gas concentration monitoring
- Climate dashboard widgets
- Educational climate apps
- Quick prototyping of climate visualizations
- Mobile app integration (no auth complexity)
- Browser-based climate data applications

### Integration Notes
- **Complexity**: VERY LOW - Simple REST API, no authentication
- **Reliability**: Community-maintained, may have occasional downtime
- **Example cURL**:
  ```bash
  curl https://global-warming.org/api/temperature-api
  curl https://global-warming.org/api/co2-api
  ```
- **Example JavaScript**:
  ```javascript
  fetch('https://global-warming.org/api/temperature-api')
    .then(response => response.json())
    .then(data => console.log(data));
  ```
- **Rate Limits**: Not documented, use reasonable request frequency
- **Caching**: Recommended to cache responses (data updates monthly/daily)
- **Production Use**: Consider this a supplementary source; primary sources (NASA, NOAA) may be more reliable for critical applications

---

## Summary Comparison Matrix

| Dataset | Source | Update Freq | Format | Auth Required | Complexity | Best For |
|---------|--------|-------------|--------|---------------|------------|----------|
| NASA GISTEMP | NASA GISS | Monthly | CSV, NetCDF | No | LOW | Global temperature trends |
| NOAA CDO API | NOAA NCEI | Daily | JSON | Yes (free) | MEDIUM | Station-based weather data |
| OWID CO2 | Our World in Data | Annually | CSV, JSON, XLSX | No | LOW | Emissions tracking |
| Copernicus ERA5 | ECMWF | Daily | NetCDF | Yes (free) | HIGH | High-res reanalysis |
| Global Warming API | Community | Monthly/Daily | JSON | No | VERY LOW | Quick GHG monitoring |

## Integration Priority Recommendations

### Priority 1: Quick Wins (Start Here)
1. **Global Warming API** - Easiest to integrate, immediate value for dashboards
2. **Our World in Data CO2** - Single CSV download, comprehensive emissions data
3. **NASA GISTEMP** - Simple temperature data, authoritative source

### Priority 2: Core Climate Metrics
4. **NOAA CDO API** - More complex but provides granular location-based data
5. **Copernicus ERA5** - High-value but requires NetCDF expertise and storage planning

## Next Steps

1. **Proof of Concept**: Start with Global Warming API for rapid prototyping
2. **Production Data**: Implement OWID CO2 and NASA GISTEMP for reliable historical data
3. **Advanced Analytics**: Add NOAA CDO for location-specific insights
4. **Research Grade**: Integrate Copernicus ERA5 for comprehensive climate modeling

## Technical Implementation Notes

### Recommended GCP Architecture
```
Global Warming API → Cloud Scheduler → Cloud Functions → BigQuery
OWID CO2 CSV → Cloud Storage → Dataflow → BigQuery (annual batch)
NASA GISTEMP → Cloud Scheduler → Cloud Functions → BigQuery (monthly)
NOAA CDO API → Cloud Scheduler → Cloud Functions → BigQuery (daily)
Copernicus ERA5 → Cloud Storage → Dataproc → BigQuery (batch processing)
```

### Storage Estimates
- **Global Warming API**: <1 MB total
- **OWID CO2**: ~15 MB per year
- **NASA GISTEMP**: ~1 MB total
- **NOAA CDO**: Variable (depends on stations/parameters)
- **Copernicus ERA5**: 100s of GB to TBs (subsetting critical)

### Suggested Data Warehouse Schema
- **Fact Tables**: `climate_temperature`, `ghg_concentrations`, `emissions_by_country`
- **Dimension Tables**: `countries`, `weather_stations`, `time_periods`
- **Partitioning**: By year/month for time series data
- **Clustering**: By country/region for geographic queries

---

**Document Prepared By**: Climate Dataset Research Agent
**Date**: 2025-11-14
**Purpose**: Data Engineering Integration Reference
