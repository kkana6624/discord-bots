defmodule RoleController.EvaluatorTest do
  use ExUnit.Case, async: true
  alias RoleController.Evaluator

  @role_a 100
  @role_b 200
  @role_c 300

  test "returns :add when user has A and B but not C" do
    assert Evaluator.evaluate([@role_a, @role_b], @role_a, @role_b, @role_c) == :add
    assert Evaluator.evaluate([@role_a, @role_b, 400], @role_a, @role_b, @role_c) == :add
  end

  test "returns :remove when user has only A and C" do
    assert Evaluator.evaluate([@role_a, @role_c], @role_a, @role_b, @role_c) == :remove
  end

  test "returns :remove when user has only B and C" do
    assert Evaluator.evaluate([@role_b, @role_c], @role_a, @role_b, @role_c) == :remove
  end

  test "returns :remove when user has neither A nor B but has C" do
    assert Evaluator.evaluate([@role_c], @role_a, @role_b, @role_c) == :remove
  end

  test "returns :keep when user has A, B, and C" do
    assert Evaluator.evaluate([@role_a, @role_b, @role_c], @role_a, @role_b, @role_c) == :keep
  end

  test "returns :keep when user has only A" do
    assert Evaluator.evaluate([@role_a], @role_a, @role_b, @role_c) == :keep
  end

  test "returns :keep when user has only B" do
    assert Evaluator.evaluate([@role_b], @role_a, @role_b, @role_c) == :keep
  end

  test "returns :keep when user has neither A, B, nor C" do
    assert Evaluator.evaluate([], @role_a, @role_b, @role_c) == :keep
  end
end
