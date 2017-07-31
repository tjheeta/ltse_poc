defmodule LtsePoc.Application do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      # Start the endpoint when the application starts
      supervisor(LtsePocWeb.Endpoint, []),
      supervisor(LtsePoc.Exchange.Trade.WorkerSupervisor, []),
      # Start your own worker by calling: LtsePoc.Worker.start_link(arg1, arg2, arg3)
      # worker(LtsePoc.Worker, [arg1, arg2, arg3]),
    ]
    children = case Application.get_env(:ltse_poc, LtsePoc.Repo)[:enabled] do
      nil -> children ++ [supervisor(LtsePoc.Repo, [])]
      _ -> children
    end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LtsePoc.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    LtsePocWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
