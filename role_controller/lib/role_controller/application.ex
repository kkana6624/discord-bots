defmodule RoleController.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = 
      if Mix.env() == :test do
        []
      else
        [
          RoleController.EventConsumer,
          RoleController.Reconciler
        ]
      end

    opts = [strategy: :one_for_one, name: RoleController.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
