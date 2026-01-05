# Milwaukee Skipper

A Rails API that delivers real-time Lake Michigan sailing conditions to [TRMNL](https://usetrmnl.com) e-ink displays. Built for sailors who want instant, glanceable weather data optimized for the Milwaukee harbor.

![Ruby](https://img.shields.io/badge/Ruby-3.3-red)
![Rails](https://img.shields.io/badge/Rails-8.1-red)
![License](https://img.shields.io/badge/license-MIT-blue)

## The Curt Index

The heart of Milwaukee Skipper is the **Curt Index** - a custom sailability rating that translates raw weather data into actionable sailing decisions:

| Level | Icon | Wind | Waves | What it means |
|-------|------|------|-------|---------------|
| **CALM** | ——— | < 8 kt | any | Light air, motoring weather |
| **ACE TITS** | ~~~ | 8-15 kt | < 3 ft | Ideal sailing conditions |
| **SPORTY** | ~~~ | 15-20 kt | 3-5 ft | Reef early, experienced sailors |
| **ROUGH** | ~~~ | > 20 kt | > 5 ft | Stay ashore |

## Features

- **Real-time dock observations** from NOAA NDBC buoy MLWW3 (Milwaukee)
- **Offshore buoy data** from NDBC 45007 (Southern Lake Michigan)
- **Hourly forecasts** from Open-Meteo's marine and weather APIs
- **NWS forecast summaries** from the Milwaukee/Sullivan office
- **10-minute caching** to respect API rate limits
- **TRMNL plugin templates** for full, half, and quadrant layouts

## Data Sources

| Data | Source | Update Frequency |
|------|--------|------------------|
| Dock wind/temp | [NDBC MLWW3](https://www.ndbc.noaa.gov/station_page.php?station=mlww3) | 10 min |
| Offshore conditions | [NDBC 45007](https://www.ndbc.noaa.gov/station_page.php?station=45007) | Hourly |
| Wind/wave forecast | [Open-Meteo Marine API](https://open-meteo.com/en/docs/marine-weather-api) | Hourly |
| Forecast summary | [NWS API](https://api.weather.gov) | 6 hours |

## API

### `GET /api/mke/current`

Returns current conditions, forecast, and sailability rating.

```json
{
  "location": {
    "name": "Milwaukee",
    "lat": 43.04,
    "lon": -87.89
  },
  "observations": {
    "source": "NOAA NDBC",
    "dock": {
      "name": "Milwaukee Dock",
      "wind_speed_kt": 12,
      "wind_gust_kt": 18,
      "wind_dir_deg": 225,
      "wind_dir_cardinal": "SW",
      "air_temp_f": 42
    },
    "offshore": {
      "name": "Lake Michigan S",
      "wind_speed_kt": 15,
      "wave_height_ft": 2.8,
      "wave_period_s": 5.2,
      "water_temp_f": 48
    }
  },
  "forecast": {
    "source": "Open-Meteo + NWS",
    "summary": "Partly cloudy with southwest winds 10-15 knots...",
    "hours": [
      {
        "time": "2025-01-05T14:00",
        "wind_speed_kt": 12,
        "wind_gust_kt": 18,
        "wind_dir_cardinal": "SW",
        "wave_height_ft": 2.5
      }
    ]
  },
  "sailability": {
    "level": "great",
    "reason": "Ideal sailing conditions.",
    "score": 0.8
  },
  "updated_at": "2025-01-05T14:32:00"
}
```

## TRMNL Plugin

The `trmnl-plugin/` directory contains Liquid templates for TRMNL displays:

```
trmnl-plugin/
├── views/
│   ├── full.liquid           # Full-screen 3x2 grid layout
│   ├── half_horizontal.liquid
│   ├── quadrant.liquid
│   └── shared.liquid
├── config.toml
└── sample_data.json
```

### Dashboard Layout (Full Screen)

```
┌─────────────────┬─────────────────┬─────────────────┐
│   CURT INDEX    │      DOCK       │      LAKE       │
│      ~~~        │       12        │       15        │
│   ACE TITS      │    kt SW        │    kt SW        │
│ "Ace Tits..."   │                 │                 │
├─────────────────┼─────────────────┼─────────────────┤
│   CONDITIONS    │     WAVES       │    FORECAST     │
│    42° Air      │  2.5→2.0ft      │ Partly cloudy,  │
│    18kt Gust    │   Subsiding     │ SW winds 10-15  │
└─────────────────┴─────────────────┴─────────────────┘
  ⚓ Good afternoon, Captain Curt              2:32 PM
```

## Local Development

### Prerequisites

- Ruby 3.3+
- SQLite3

### Setup

```bash
cd milwaukee-skipper
bundle install
bin/rails db:setup
bin/dev
```

### Test the API

```bash
curl http://localhost:3000/api/mke/current | jq
```

### TRMNL Plugin Development

Use [trmnlp](https://github.com/usetrmnl/trmnlp) to preview templates locally:

```bash
cd trmnl-plugin
trmnlp serve
```

## Deployment

Deployed on [Fly.io](https://fly.io) in the `ord` (Chicago) region for low latency to Milwaukee data sources.

```bash
fly deploy
```

### Live API

```
https://milwaukee-skipper-weathered-morning-2608.fly.dev/api/mke/current
```

## Project Structure

```
milwaukee-skipper/
├── app/
│   ├── controllers/
│   │   └── conditions_controller.rb   # API endpoint
│   └── models/
│       └── lake_conditions.rb         # Data aggregation & Curt Index
├── trmnl-plugin/                       # TRMNL Liquid templates
├── config/
├── fly.toml                            # Fly.io deployment config
└── CURT_INDEX_GUIDE.md                 # Reference documentation
```

## How It Was Built

This project was built collaboratively with Claude Code (Anthropic's AI coding assistant). The development process included:

1. **Planning** - Defined the PRD with data sources, API structure, and TRMNL integration requirements
2. **API Development** - Built the Rails API with multi-source data aggregation
3. **Curt Index Design** - Created the sailability algorithm based on local sailing knowledge
4. **TRMNL Templates** - Designed Liquid templates optimized for e-ink displays
5. **Deployment** - Configured Fly.io for production hosting

The entire codebase was developed through iterative prompts, with Claude handling everything from NDBC data parsing to Liquid template layout.

## License

MIT

---

*Fair winds, Captain!* ⚓
