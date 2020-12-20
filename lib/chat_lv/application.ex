defmodule ChatLv.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    topologies = [
      k8s_chat: [
        strategy: Cluster.Strategy.Kubernetes.DNS,
        config: [
          service: "chat-nodes",
          application_name: "chat"
        ]
      ]
    ]

    children = [
      ChatLv.Repo,
      ChatLvWeb.Telemetry,
      {Phoenix.PubSub, name: ChatLv.PubSub},
      ChatLvWeb.Endpoint,
      {Cluster.Supervisor, [topologies, [name: ChatLv.ClusterSupervisor]]},
    ]

    opts = [strategy: :one_for_one, name: ChatLv.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    ChatLvWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
