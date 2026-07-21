defmodule RoleController.Evaluator do
  @doc """
  Evaluates whether the target role should be added, removed, or kept.
  """
  def evaluate(current_roles, role_a_id, role_b_id, target_role_c_id) do
    has_a? = role_a_id in current_roles
    has_b? = role_b_id in current_roles
    has_c? = target_role_c_id in current_roles

    cond do
      has_a? and has_b? and not has_c? -> :add
      (not has_a? or not has_b?) and has_c? -> :remove
      true -> :keep
    end
  end
end
