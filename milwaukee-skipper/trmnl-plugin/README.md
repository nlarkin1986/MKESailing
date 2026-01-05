# Captain Curt's Milwaukee Skipper - TRMNL Plugin

A personalized nautical dashboard for Lake Michigan sailing conditions, designed for TRMNL e-ink displays.

## Features

- **Personalized Messages**: Dynamic greetings based on conditions and time of day
- **Visual Wind Indicators**: Beaufort scale icons for instant wind assessment
- **Dual Station View**: Compare dock conditions vs offshore
- **6-Hour Forecast**: Visual trend with wind direction arrows and wave symbols
- **E-ink Optimized**: Grayscale icons and ASCII wave representations

## Layouts

- `full.liquid` - Full screen dashboard with all details
- `half_horizontal.liquid` - Compact version for mashups
- `quadrant.liquid` - Minimal wind-only view

## Data Sources

- **Dock Observations**: NOAA NDBC Station MLWW3 (Milwaukee Port)
- **Offshore Forecast**: Open-Meteo Marine API
- **Weather Summary**: National Weather Service

## Installation

### Via TRMNL Recipe
Import from: `https://milwaukee-skipper-weathered-morning-2608.fly.dev/api/mke/current`

### Manual Installation
1. Download this plugin folder
2. Zip the `src/` folder
3. Import via TRMNL Private Plugin > Import New
4. Configure polling URL if needed

## Local Development

Requires `trmnlp` gem (Ruby 3.x):

```bash
# Install the preview tool
gem install trmnl_preview

# Start local server (from plugin directory)
cd trmnl-plugin
trmnlp serve .

# Open browser to http://localhost:4567
```

The server will:
- Fetch live data from the API on startup
- Auto-reload when you edit `.liquid` files
- Show full, half, and quadrant layouts

## API Endpoint

```
GET https://milwaukee-skipper-weathered-morning-2608.fly.dev/api/mke/current
```

Returns JSON with:
- `location` - Milwaukee coordinates
- `observations.dock` - Real-time dock wind/temp
- `observations.offshore` - Offshore buoy data (seasonal)
- `forecast.hours[]` - Hourly forecast with wind/waves
- `forecast.summary` - NWS text forecast
- `sailability` - Calculated sailing conditions (calm/great/sporty/rough)

## Captain Curt's Messages

| Condition | Example Message |
|-----------|-----------------|
| GREAT (morning) | "Fair winds this morning, Capt. Curt! Time to make sail." |
| GREAT (afternoon) | "Perfect sailing weather, Captain. The lake is calling." |
| CALM | "Light air today, Captain. Good for a leisurely drift." |
| SPORTY | "Lively conditions out there, Capt. Curt! Reef early if needed." |
| ROUGH | "Careful out there, Captain Curt. Heavy weather brewing." |

## License

MIT
