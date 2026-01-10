defmodule Karabinex.Manipulator.DSLTest do
  use ExUnit.Case

  alias Karabinex.Manipulator.DSL
  alias Karabinex.Key

  describe "manipulate/1" do
    test "creates basic type manipulator from key" do
      key = Key.new("x")

      result = DSL.manipulate(key)

      assert result.type == :basic
      assert result.from == %{key_code: "x"}
    end

    test "creates manipulator with modifiers" do
      key = Key.new("M-x")

      result = DSL.manipulate(key)

      assert result.type == :basic
      assert result.from.key_code == "x"
      assert result.from.modifiers.mandatory == [:option]
    end
  end

  describe "from/2" do
    test "sets from clause for key" do
      key = Key.new("a")

      result = DSL.from(%{type: :basic}, key)

      assert result.from == %{key_code: "a"}
    end

    test "sets from clause for :any" do
      result = DSL.from(%{type: :basic}, :any)

      assert result.from == %{any: :key_code}
    end

    test "sets from clause for key_code map" do
      result = DSL.from(%{type: :basic}, %{key_code: "escape"})

      assert result.from == %{key_code: "escape"}
    end
  end

  describe "remap/2" do
    test "appends to clause" do
      result =
        %{type: :basic}
        |> DSL.remap(%{key_code: "escape"})

      assert result.to == [%{key_code: "escape"}]
    end

    test "appends multiple remaps" do
      result =
        %{type: :basic}
        |> DSL.remap(%{key_code: "a"})
        |> DSL.remap(%{key_code: "b"})

      assert result.to == [%{key_code: "a"}, %{key_code: "b"}]
    end
  end

  describe "run_shell_command/2" do
    test "appends shell command to clause" do
      result =
        %{type: :basic}
        |> DSL.run_shell_command("echo hello")

      assert result.to == [%{shell_command: "echo hello"}]
    end
  end

  describe "set_variable/2,3" do
    test "sets variable with default value 1" do
      result =
        %{type: :basic}
        |> DSL.set_variable("my_var")

      assert result.to == [%{set_variable: %{name: "my_var", value: 1}}]
    end

    test "sets variable with custom value" do
      result =
        %{type: :basic}
        |> DSL.set_variable("my_var", 42)

      assert result.to == [%{set_variable: %{name: "my_var", value: 42}}]
    end
  end

  describe "unset_variable/2" do
    test "unsets variable" do
      result =
        %{type: :basic}
        |> DSL.unset_variable("my_var")

      assert result.to == [%{set_variable: %{name: "my_var", type: "unset"}}]
    end
  end

  describe "unset_variable_after_key_up/2" do
    test "adds to to_after_key_up clause" do
      result =
        %{type: :basic}
        |> DSL.unset_variable_after_key_up("my_var")

      assert result.to_after_key_up == [%{set_variable: %{name: "my_var", type: "unset"}}]
    end
  end

  describe "if_variable/2,3" do
    test "adds condition with default value 1" do
      result =
        %{type: :basic}
        |> DSL.if_variable("my_var")

      assert result.conditions == [%{type: :variable_if, name: "my_var", value: 1}]
    end

    test "adds condition with custom value" do
      result =
        %{type: :basic}
        |> DSL.if_variable("my_var", 5)

      assert result.conditions == [%{type: :variable_if, name: "my_var", value: 5}]
    end
  end

  describe "unless_variable/2" do
    test "adds condition with value 0" do
      result =
        %{type: :basic}
        |> DSL.unless_variable("my_var")

      assert result.conditions == [%{type: :variable_if, name: "my_var", value: 0}]
    end
  end

  describe "unless_variables/2" do
    test "adds multiple conditions" do
      result =
        %{type: :basic}
        |> DSL.unless_variables(["var1", "var2"])

      assert length(result.conditions) == 2
      assert Enum.at(result.conditions, 0) == %{type: :variable_if, name: "var1", value: 0}
      assert Enum.at(result.conditions, 1) == %{type: :variable_if, name: "var2", value: 0}
    end

    test "handles empty list" do
      result =
        %{type: :basic}
        |> DSL.unless_variables([])

      refute Map.has_key?(result, :conditions)
    end
  end
end
