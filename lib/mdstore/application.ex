defmodule Mdstore.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MdstoreWeb.Telemetry,
      Mdstore.Repo,
      {DNSCluster, query: Application.get_env(:mdstore, :dns_cluster_query) || :ignore},
      {Oban, Application.fetch_env!(:mdstore, Oban)},
      {Phoenix.PubSub, name: Mdstore.PubSub},
      Application.get_env(:mdstore, :cache_backend).child_spec(),
      # Start a worker by calling: Mdstore.Worker.start_link(arg)
      # {Mdstore.Worker, arg},
      # Start to serve requests, typically the last entry
      MdstoreWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Mdstore.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MdstoreWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
