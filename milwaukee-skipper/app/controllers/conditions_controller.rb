class ConditionsController < ActionController::API

  def show
    @conditions = LakeConditions.current
    render json: @conditions
  rescue => e
    Rails.logger.error("ConditionsController#show failed: #{e.message}")
    render json: {
      location: { name: "Milwaukee", lat: 43.04, lon: -87.89 },
      observations: { source: "unavailable", dock: { error: e.message }, offshore: { error: e.message } },
      forecast: { source: "unavailable", summary: nil, advisory: nil, hours: [] },
      sailability: { level: "calm", reason: "Data temporarily unavailable.", score: 0 },
      updated_at: Time.current.in_time_zone("America/Chicago").iso8601
    }, status: :ok
  end
end
