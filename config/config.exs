# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :chat_lv,
  ecto_repos: [ChatLv.Repo]

# Configures the endpoint
config :chat_lv, ChatLvWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "JCoXpfTogfohYTNTtinpgG1NIKbpElL9XCl7XWNkA/B9fvlDAY02Fr3nYf6T2U/r",
  render_errors: [view: ChatLvWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: ChatLv.PubSub,
  live_view: [signing_salt: "d8QJqWq/"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
