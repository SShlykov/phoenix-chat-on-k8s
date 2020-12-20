use Mix.Config
db_url          = System.get_env("DB_URL") || "ecto://postgres:postgres@localhost/chat_lv_dev"
port            = System.get_env("PORT") || 4000
host            = System.get_env("PHOENIX_CHAT_HOST") || "localhost"
secret_key_base = System.get_env("SECRET_KEY_BASE") || "XR7e8rPXq2nIdBXqtPsyxPz1R1UF3w4HDBFGdxZ+9GDZCT6PpG4aJLpOzehOJVO5"

config :chat_lv, ChatLvWeb.Endpoint,
  http: [port: port],
  url:  [host: host],
  check_origin: false,
  transport_options: [socket_opts: [:inet6]],
  cache_static_manifest: "priv/static/cache_manifest.json",
  secret_key_base: secret_key_base,
  server: true

config :logger, level: :info

config :chat_lv, ChatLv.Repo,
  url: db_url,
  pool_size: 10
