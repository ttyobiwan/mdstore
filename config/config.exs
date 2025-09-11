# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :mdstore, :scopes,
  user: [
    default: true,
    module: Mdstore.Accounts.Scope,
    assign_key: :current_scope,
    access_path: [:user, :id],
    schema_key: :user_id,
    schema_type: :id,
    schema_table: :users,
    test_data_fixture: Mdstore.AccountsFixtures,
    test_setup_helper: :register_and_log_in_user
  ]

config :mdstore,
  ecto_repos: [Mdstore.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :mdstore, MdstoreWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: MdstoreWeb.ErrorHTML, json: MdstoreWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Mdstore.PubSub,
  live_view: [signing_salt: "pOEhyBbG"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :mdstore, Mdstore.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  mdstore: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.7",
  mdstore: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configures file storage for uploads
config :mdstore, :file_storage, Mdstore.Files.Storages.Local

# Configures payment processor
config :stripity_stripe,
  api_key: System.get_env("STRIPE_SECRET"),
  publishable_key: System.get_env("STRIPE_PUBLISHABLE_KEY")

config :mdstore, :payment_processor, Mdstore.Payments.Stripe

# Configurations for cache backend

# Configures Cachex
config :mdstore, :cache_backend, Mdstore.Cache.Cachex
config :mdstore, :cachex, name: :cachex_default

# Configures Redis
# config :mdstore, :cache_backend, Mdstore.Cache.Redis
# config :mdstore, :redis,
#   name: :redis_default,
#   host: System.get_env("REDIS_HOST"),
#   port: 6379

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
