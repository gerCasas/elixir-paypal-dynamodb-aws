# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :pay,
  ecto_repos: [Pay.Repo]

# Configures the endpoint
config :pay, Pay.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "V02d28bb5q7VChud/JDYs/y88kGakW3cqzjPPDBqi/inl929HItOWBL3VZy+wLxv",
  render_errors: [view: Pay.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Pay.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

#config :ex_aws,
#  access_key_id: [{:system, "AWS_ACCESS_KEY_ID"}, {:awscli, "aws_dynamo", 30}, :instance_role],
#  secret_access_key: [{:system, "AWS_SECRET_ACCESS_KEY"}, {:awscli, "aws_dynamo", 30}, :instance_role],
#  region: "us-west-2"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
