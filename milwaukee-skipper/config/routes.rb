Rails.application.routes.draw do
  # Main API endpoint for TRMNL polling
  get "/api/mke/current", to: "conditions#show"

  # Health check endpoints
  get "up" => "rails/health#show", as: :rails_health_check
  get "healthz", to: proc { [200, { "Content-Type" => "text/plain" }, ["ok"]] }

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
