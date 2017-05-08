use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :pay, Pay.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [node: ["node_modules/brunch/bin/brunch", "watch", "--stdin",
                    cd: Path.expand("../", __DIR__)]]

# payPalConfiguration
# source keys.env
config :pay, :paypal,
  client_id: "AYj1ueGrp9HCpbyLhEYuf7fMXGC36z5v6-O5ccDFAgmPTSesuYH49NH4qfBThQmpWu6hedTmhD2fEKHd",
  secret: "EDGDf6_kXpmfOM87xDaMMWHD427Pg3sIB4ahvlHZo5iSRUntLZUTEDDkT6MW9oss55kG8hIp1YAAhm7E",
  env: :sandbox

# AWS DynamoDB
config :ex_aws,
  access_key_id: [System.get_env("AWS_ACCESS_KEY_ID"), {:awscli, "aws_dynamo", 30}, :instance_role],
  secret_access_key: [System.get_env("AWS_SECRET_ACCESS_KEY"), {:awscli, "aws_dynamo", 30}, :instance_role],
  region: "us-west-2",
  debug_requests: true

# Watch static and templates for browser reloading.
config :pay, Pay.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{web/views/.*(ex)$},
      ~r{web/templates/.*(eex)$}
    ]
  ]

  IO.puts("+++++++++++++")
  IO.inspect(System.get_env("AWS_ACCESS_KEY_ID"))
  IO.inspect(System.get_env("AWS_SECRET_ACCESS_KEY"))
  IO.puts("+++++++++++++")

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Configure your database
config :pay, Pay.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "german",
  password: "",
  database: "pay_client_dev",
  hostname: "localhost",
  pool_size: 10
