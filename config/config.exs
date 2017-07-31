# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :ltse_poc,
  ecto_repos: [LtsePoc.Repo]

# Configures the endpoint
config :ltse_poc, LtsePocWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "oXXTWDg+ylJL953XlpDq8DAFgNdKdFcQWEv40nipcM+VdulzuIusEQiIU81ZGxjP",
  render_errors: [view: LtsePocWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: LtsePoc.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  level: :warn,
  metadata: [:request_id]


config :mix_docker, image: "tjheeta/ltse_poc"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
