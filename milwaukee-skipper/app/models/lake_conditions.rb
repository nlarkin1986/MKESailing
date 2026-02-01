class LakeConditions
  CACHE_TTL = 10.minutes
  MKE_LAT = 43.04
  MKE_LON = -87.89
  USER_AGENT = "MilwaukeeSkipper/1.0 (Lake Conditions for TRMNL)"

  def self.current
    Rails.cache.fetch("lake_conditions:mke", expires_in: CACHE_TTL) do
      new.build
    end
  end

  def build
    obs = fetch_observations
    forecast = fetch_forecast

    {
      location: { name: "Milwaukee", lat: MKE_LAT, lon: MKE_LON },
      observations: obs,
      forecast: forecast,
      sailability: calculate_sailability(obs, forecast),
      updated_at: Time.current.in_time_zone("America/Chicago").iso8601
    }
  end

  private

  # NDBC observations from Milwaukee Port (MLWW3) and offshore buoys
  def fetch_observations
    dock = fetch_ndbc_station("MLWW3", "Milwaukee Dock")
    offshore = fetch_ndbc_station("45007", "Lake Michigan S") # Southern Lake Michigan buoy

    {
      source: "NOAA NDBC",
      dock: dock,
      offshore: offshore
    }
  end

  def fetch_ndbc_station(station_id, name)
    url = "https://www.ndbc.noaa.gov/data/realtime2/#{station_id}.txt"
    response = HTTParty.get(url, timeout: 5, headers: { "User-Agent" => USER_AGENT })

    return empty_station(name, "fetch failed") unless response.success?

    lines = response.body.lines.reject { |l| l.start_with?("#") }
    return empty_station(name, "no data") if lines.empty?

    # Parse most recent observation (first data line)
    parts = lines.first.split
    return empty_station(name, "parse error") if parts.length < 14

    # Check data freshness (within last 2 hours)
    obs_time = Time.utc(parts[0].to_i, parts[1].to_i, parts[2].to_i, parts[3].to_i, parts[4].to_i)
    if (Time.now.utc - obs_time) > 2.hours
      return empty_station(name, "stale data")
    end

    wdir = parse_ndbc_value(parts[5])
    wspd = parse_ndbc_value(parts[6])
    gst = parse_ndbc_value(parts[7])
    wvht = parse_ndbc_value(parts[8])
    dpd = parse_ndbc_value(parts[9])
    atmp = parse_ndbc_value(parts[13])
    wtmp = parse_ndbc_value(parts[14])

    {
      name: name,
      wind_speed_kt: wspd ? ms_to_knots(wspd) : nil,
      wind_gust_kt: gst ? ms_to_knots(gst) : nil,
      wind_dir_deg: wdir&.round,
      wind_dir_cardinal: deg_to_cardinal(wdir),
      air_temp_f: atmp ? c_to_f(atmp) : nil,
      water_temp_f: wtmp ? c_to_f(wtmp) : nil,
      wave_height_ft: wvht ? m_to_feet(wvht) : nil,
      wave_period_s: dpd&.round(1)
    }
  rescue => e
    Rails.logger.error("NDBC #{station_id} failed: #{e.message}")
    empty_station(name, e.message)
  end

  def parse_ndbc_value(val)
    return nil if val.nil? || val == "MM" || val == "999" || val == "99.0"
    val.to_f
  end

  def empty_station(name, reason = nil)
    {
      name: name,
      wind_speed_kt: nil,
      wind_gust_kt: nil,
      wind_dir_deg: nil,
      wind_dir_cardinal: nil,
      air_temp_f: nil,
      water_temp_f: nil,
      wave_height_ft: nil,
      wave_period_s: nil,
      error: reason
    }
  end

  def fetch_forecast
    weather = fetch_open_meteo_weather
    marine = fetch_open_meteo_marine
    nws_summary = fetch_nws_summary

    hours = merge_forecast_hours(weather, marine)

    {
      source: "Open-Meteo + NWS",
      summary: nws_summary,
      advisory: nil,
      hours: hours.first(6)
    }
  rescue => e
    Rails.logger.error("Forecast fetch failed: #{e.message}")
    { source: "unavailable", summary: nil, advisory: nil, hours: [], error: e.message }
  end

  def fetch_open_meteo_weather
    url = "https://api.open-meteo.com/v1/forecast"
    response = HTTParty.get(url, timeout: 5, query: {
      latitude: MKE_LAT,
      longitude: MKE_LON,
      hourly: "wind_speed_10m,wind_gusts_10m,wind_direction_10m,temperature_2m",
      forecast_days: 2,
      timezone: "America/Chicago"
    })

    return nil unless response.success?
    response.parsed_response
  rescue => e
    Rails.logger.error("Open-Meteo weather failed: #{e.message}")
    nil
  end

  def fetch_open_meteo_marine
    url = "https://marine-api.open-meteo.com/v1/marine"
    response = HTTParty.get(url, timeout: 5, query: {
      latitude: MKE_LAT,
      longitude: MKE_LON,
      hourly: "wave_height,wave_period",
      forecast_days: 2,
      timezone: "America/Chicago"
    })

    return nil unless response.success?
    response.parsed_response
  rescue => e
    Rails.logger.error("Open-Meteo marine failed: #{e.message}")
    nil
  end

  def fetch_nws_summary
    # NWS gridpoint for Milwaukee: LMK/87,65 (Lake Michigan forecast)
    url = "https://api.weather.gov/gridpoints/MKX/87,65/forecast"
    response = HTTParty.get(url, timeout: 5, format: :json, headers: {
      "User-Agent" => USER_AGENT,
      "Accept" => "application/json"
    })

    return nil unless response.success?

    data = response.parsed_response
    periods = data.dig("properties", "periods")
    return nil if periods.blank?

    # Get the current period's detailed forecast
    current = periods.first
    current["detailedForecast"]&.truncate(200)
  rescue => e
    Rails.logger.error("NWS fetch failed: #{e.message}")
    nil
  end

  def merge_forecast_hours(weather, marine)
    return [] if weather.nil?

    times = weather.dig("hourly", "time") || []
    wind_speed = weather.dig("hourly", "wind_speed_10m") || []
    wind_gust = weather.dig("hourly", "wind_gusts_10m") || []
    wind_dir = weather.dig("hourly", "wind_direction_10m") || []
    temp = weather.dig("hourly", "temperature_2m") || []

    wave_height = marine&.dig("hourly", "wave_height") || []
    wave_period = marine&.dig("hourly", "wave_period") || []

    # Find current hour index
    now = Time.current.in_time_zone("America/Chicago")
    current_hour = now.beginning_of_hour.strftime("%Y-%m-%dT%H:%M")
    start_idx = times.index { |t| t >= current_hour } || 0

    # Build next 12 hours
    (start_idx...[start_idx + 12, times.length].min).map do |i|
      ws = wind_speed[i]
      wg = wind_gust[i]
      wd = wind_dir[i]
      wh = wave_height[i]
      wp = wave_period[i]

      {
        time: times[i],
        wind_speed_kt: ws ? kmh_to_knots(ws) : nil,
        wind_gust_kt: wg ? kmh_to_knots(wg) : nil,
        wind_dir_deg: wd,
        wind_dir_cardinal: deg_to_cardinal(wd),
        air_temp_f: temp[i] ? c_to_f(temp[i]) : nil,
        wave_height_ft: wh ? m_to_feet(wh) : nil,
        wave_period_s: wp
      }
    end
  end

  def calculate_sailability(obs, forecast)
    # Use forecast data if observations unavailable
    current_hour = forecast[:hours]&.first || {}
    wind = current_hour[:wind_speed_kt] || obs.dig(:offshore, :wind_speed_kt) || 0
    waves = current_hour[:wave_height_ft] || obs.dig(:offshore, :wave_height_ft) || 0

    # Curt Index levels:
    # ROUGH:    > 20kt wind OR > 5ft waves
    # SPORTY:   15-20kt wind OR 3-5ft waves
    # ACE TITS: 8-15kt wind, < 3ft waves (ideal sailing)
    # CALM:     < 8kt wind
    if wind > 20 || waves > 5
      { level: "rough", reason: "Heavy weather conditions.", score: 0.1 }
    elsif wind >= 15 || waves >= 3
      { level: "sporty", reason: "Challenging but manageable.", score: 0.6 }
    elsif wind >= 8
      { level: "great", reason: "Ideal sailing conditions.", score: 0.8 }
    else
      { level: "calm", reason: "Light air, bring your patience.", score: 0.4 }
    end
  end

  # Unit conversions
  def kmh_to_knots(kmh) = (kmh * 0.539957).round(1)
  def ms_to_knots(ms) = (ms * 1.94384).round(1)
  def m_to_feet(m) = (m * 3.28084).round(1)
  def c_to_f(c) = ((c * 9.0 / 5) + 32).round(1)

  def deg_to_cardinal(deg)
    return nil if deg.nil?
    dirs = %w[N NNE NE ENE E ESE SE SSE S SSW SW WSW W WNW NW NNW]
    dirs[(deg / 22.5).round % 16]
  end
end
