defmodule ChatLv.Repo do
  use Ecto.Repo,
    otp_app: :chat_lv,
    adapter: Ecto.Adapters.Postgres
end
