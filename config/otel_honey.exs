import Config

# development environment can send telemetry, as a treat
config :opentelemetry, :processors,
  otel_batch_processor: %{
    exporter: {:opentelemetry_exporter, %{protocol: :grpc}}
  }
