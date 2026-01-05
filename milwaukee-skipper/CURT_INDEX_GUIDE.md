# Captain Curt's Skipper - Reference Guide

## Curt Index

The Curt Index is a personalized sailing conditions indicator for Lake Michigan at Milwaukee.

### Levels

| Level | Icon | Wind Speed | Wave Height | Message |
|-------|------|------------|-------------|---------|
| **CALM** | ——— | < 8 kt | any | "Light air today, Captain." |
| **ACE TITS** | ～～～ | 8-15 kt | < 3 ft | "Ace Tits out there, Curt!" |
| **SPORTY** | ∿∿∿ | 15-20 kt | OR 3-5 ft | "Reef early if needed!" |
| **ROUGH** | ≋≋≋ | > 20 kt | OR > 5 ft | "Heavy weather, Curt." |

### Decision Logic (in order)
1. **ROUGH** if wind > 20kt **OR** waves > 5ft
2. **SPORTY** if wind >= 15kt **OR** waves >= 3ft
3. **ACE TITS** if wind >= 8kt (and waves < 3ft)
4. **CALM** if wind < 8kt

### Wave Icons Explained

```
CALM:      ———      Flat water, light air
ACE TITS:  ～～～    Gentle rolling swells, ideal sailing
SPORTY:    ∿∿∿     Choppy conditions, experienced sailors
ROUGH:     ≋≋≋     Stacked waves, stay ashore
```

---

## Wind Speed Reference

### Beaufort Scale (Sailing Context)

| Beaufort | Knots | Description | Sailing Conditions |
|----------|-------|-------------|-------------------|
| 0 | 0-1 | Calm | No sailing, motoring only |
| 1 | 1-3 | Light air | Drifting conditions |
| 2 | 4-6 | Light breeze | Full sail, light hiking |
| 3 | 7-10 | Gentle breeze | Good sailing, comfortable |
| 4 | 11-16 | Moderate breeze | **Ideal sailing**, hiking out |
| 5 | 17-21 | Fresh breeze | Reef main, experienced crew |
| 6 | 22-27 | Strong breeze | Double reef, small jib |
| 7 | 28-33 | Near gale | Storm sails only |
| 8+ | 34+ | Gale | Do not sail |

### Curt Index Mapping

```
CALM       →  Beaufort 0-2  (0-6 kt)
ACE TITS   →  Beaufort 3-4  (7-16 kt)  ← Sweet spot!
SPORTY     →  Beaufort 5    (17-21 kt)
ROUGH      →  Beaufort 6+   (22+ kt)
```

---

## Data Sources

### DOCK Data (Real-time Observations)
**Source:** NOAA National Data Buoy Center (NDBC)  
**Station:** MLWW3 - Milwaukee, WI  
**URL:** https://www.ndbc.noaa.gov/station_page.php?station=mlww3  
**Update Frequency:** Every 10 minutes

| Data Point | Source |
|------------|--------|
| Dock Wind Speed | NDBC MLWW3 |
| Dock Wind Gust | NDBC MLWW3 |
| Dock Wind Direction | NDBC MLWW3 |
| Air Temperature | NDBC MLWW3 |

### LAKE Data (Forecast)
**Source:** Open-Meteo Marine Forecast API  
**URL:** https://open-meteo.com/en/docs/marine-weather-api  
**Coordinates:** 43.04°N, -87.89°W (Milwaukee)  
**Update Frequency:** Hourly forecasts

| Data Point | Source |
|------------|--------|
| Lake Wind Speed | Open-Meteo Marine |
| Lake Wind Direction | Open-Meteo Marine |
| Wave Height | Open-Meteo Marine |
| Wave Period | Open-Meteo Marine |

### FORECAST Summary
**Source:** National Weather Service (NWS)  
**Office:** Milwaukee/Sullivan, WI  
**URL:** https://api.weather.gov/points/43.04,-87.89  
**Update Frequency:** Every 6 hours

### Curt Index Calculation
The Curt Index uses data from **Open-Meteo Marine forecast** (first hour):
- `wind_speed_kt` → Primary wind input
- `wave_height_ft` → Primary wave input

Fallback to NDBC offshore buoy (45007) if forecast unavailable.

---

## Time-Based Greetings

| Time (CST) | Footer Message |
|------------|----------------|
| 5 AM - 12 PM | "Good morning, Captain Curt" |
| 12 PM - 5 PM | "Good afternoon, Captain Curt" |
| 5 PM - 9 PM | "Good evening, Captain Curt" |
| 9 PM - 5 AM | "Clear skies, Captain Curt" |

---

## Dashboard Layout

```
┌─────────────────┬─────────────────┬─────────────────┐
│   CURT INDEX    │      DOCK       │      LAKE       │
│                 │                 │                 │
│     ～～～       │       10        │       8         │
│   ACE TITS      │    kt ←ESE      │    kt ←SSE      │
│                 │                 │                 │
│ "Ace Tits..."   │                 │                 │
├─────────────────┼─────────────────┼─────────────────┤
│   CONDITIONS    │     WAVES       │    FORECAST     │
│                 │                 │                 │
│    37° Air      │  2.0→1.6ft      │ Mostly cloudy,  │
│    10kt Gust    │   Subsiding     │ high near 40... │
│                 │                 │                 │
└─────────────────┴─────────────────┴─────────────────┘
│ ⚓ Good afternoon, Captain Curt            3:34 PM  │
```

---

## API Endpoint

```
GET https://milwaukee-skipper-weathered-morning-2608.fly.dev/api/mke/current
```

### Response Structure

```json
{
  "location": { "name": "Milwaukee", "lat": 43.04, "lon": -87.89 },
  "observations": {
    "dock": { "wind_speed_kt": 10, "wind_gust_kt": 13, "wind_dir_cardinal": "NNW", "air_temp_f": 39 },
    "offshore": { ... }
  },
  "forecast": {
    "summary": "Mostly cloudy...",
    "hours": [ { "wind_speed_kt": 8, "wave_height_ft": 2.0, ... } ]
  },
  "sailability": { "level": "great", "reason": "Moderate wind and seas.", "score": 0.8 },
  "updated_at": "2025-12-26T15:34:50"
}
```

---

## Quick Reference Card

```
┌────────────────────────────────────────┐
│         CURT INDEX QUICK REF           │
├────────────────────────────────────────┤
│  ———     CALM      < 8kt    Motoring   │
│  ～～～   ACE TITS  8-15kt   Perfect!   │
│  ∿∿∿    SPORTY    15-20kt  Reef up    │
│  ≋≋≋    ROUGH     > 20kt   Stay home  │
└────────────────────────────────────────┘
```

---

*Fair winds, Captain Curt!* ⚓
