defmodule RoleController.Reconciler do
  use GenServer
  require Logger
  alias RoleController.Evaluator

  @interval 60_000 * 60 # 1 hour

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    schedule_reconciliation()
    {:ok, state}
  end

  def handle_info(:reconcile, state) do
    Logger.info("Starting periodic reconciliation")
    
    guild_id = Application.get_env(:role_controller, :guild_id) |> parse_id()
    role_a_id = Application.get_env(:role_controller, :role_a_id) |> parse_id()
    role_b_id = Application.get_env(:role_controller, :role_b_id) |> parse_id()
    target_role_c_id = Application.get_env(:role_controller, :target_role_c_id) |> parse_id()
    
    case Nostrum.Api.Guild.members(guild_id, limit: 1000) do
      {:ok, members} ->
        Enum.each(members, fn member ->
          current_roles = member.roles
          case Evaluator.evaluate(current_roles, role_a_id, role_b_id, target_role_c_id) do
            :add ->
              Logger.info("[Reconciliation] Adding target role to user #{member.user.id}")
              Nostrum.Api.Guild.add_member_role(guild_id, member.user.id, target_role_c_id, "Reconciliation: AND condition met")
            :remove ->
              Logger.info("[Reconciliation] Removing target role from user #{member.user.id}")
              Nostrum.Api.Guild.remove_member_role(guild_id, member.user.id, target_role_c_id, "Reconciliation: AND condition no longer met")
            :keep ->
              :ok
          end
        end)
      {:error, reason} ->
        Logger.error("Failed to list guild members: #{inspect(reason)}")
    end

    schedule_reconciliation()
    {:noreply, state}
  end

  defp schedule_reconciliation do
    Process.send_after(self(), :reconcile, @interval)
  end

  defp parse_id(id) when is_integer(id), do: id
  defp parse_id(id) when is_binary(id), do: String.to_integer(id)
end
