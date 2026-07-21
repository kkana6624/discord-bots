defmodule RoleController.EventConsumer do
  use Nostrum.Consumer
  require Logger
  alias RoleController.Evaluator

  def start_link do
    Nostrum.Consumer.start_link(__MODULE__)
  end

  def handle_event({:GUILD_MEMBER_UPDATE, {_old_member, new_member}, _ws_state}) do
    guild_id = Application.get_env(:role_controller, :guild_id) |> parse_id()
    
    if new_member.guild_id == guild_id do
      role_a_id = Application.get_env(:role_controller, :role_a_id) |> parse_id()
      role_b_id = Application.get_env(:role_controller, :role_b_id) |> parse_id()
      target_role_c_id = Application.get_env(:role_controller, :target_role_c_id) |> parse_id()

      current_roles = new_member.roles

      case Evaluator.evaluate(current_roles, role_a_id, role_b_id, target_role_c_id) do
        :add ->
          Logger.info("Adding target role to user #{new_member.user.id}")
          Nostrum.Api.Guild.add_member_role(guild_id, new_member.user.id, target_role_c_id, "AND condition met")
        :remove ->
          Logger.info("Removing target role from user #{new_member.user.id}")
          Nostrum.Api.Guild.remove_member_role(guild_id, new_member.user.id, target_role_c_id, "AND condition no longer met")
        :keep ->
          :ok
      end
    end
  end

  def handle_event(_event) do
    :ok
  end
  
  defp parse_id(id) when is_integer(id), do: id
  defp parse_id(id) when is_binary(id), do: String.to_integer(id)
end
