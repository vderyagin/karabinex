defmodule Karabinex.KarabinerConfigTest do
  use ExUnit.Case

  alias Karabinex.KarabinerConfig

  describe "replace_rules_in_config/2" do
    test "replaces matching rules in profiles" do
      config = %{
        "profiles" => [
          %{
            "name" => "default",
            "complex_modifications" => %{
              "rules" => [
                %{"description" => "karabinex bindings", "manipulators" => [%{"type" => "basic"}]},
                %{"description" => "other", "manipulators" => [%{"type" => "basic"}]}
              ]
            }
          },
          %{
            "name" => "blank",
            "complex_modifications" => nil
          }
        ]
      }

      new_rules = [
        %{"description" => "karabinex bindings", "manipulators" => [%{"type" => "test"}]}
      ]

      result = KarabinerConfig.replace_rules_in_config(config, new_rules)

      assert result["profiles"] |> Enum.at(0) |> get_in(["complex_modifications", "rules"]) == [
               %{"description" => "karabinex bindings", "manipulators" => [%{"type" => "test"}]},
               %{"description" => "other", "manipulators" => [%{"type" => "basic"}]}
             ]

      assert result["profiles"] |> Enum.at(1) == Enum.at(config["profiles"], 1)
    end

    test "drops duplicate matching rules and inserts new rules once" do
      config = %{
        "profiles" => [
          %{
            "name" => "default",
            "complex_modifications" => %{
              "rules" => [
                %{"description" => "karabinex bindings", "manipulators" => [%{"id" => 1}]},
                %{"description" => "other", "manipulators" => [%{"id" => 2}]},
                %{"description" => "karabinex bindings", "manipulators" => [%{"id" => 3}]}
              ]
            }
          }
        ]
      }

      new_rules = [
        %{"description" => "karabinex bindings", "manipulators" => [%{"id" => :new}]}
      ]

      result = KarabinerConfig.replace_rules_in_config(config, new_rules)

      assert get_in(result, ["profiles", Access.at(0), "complex_modifications", "rules"]) == [
               %{"description" => "karabinex bindings", "manipulators" => [%{"id" => :new}]},
               %{"description" => "other", "manipulators" => [%{"id" => 2}]}
             ]
    end

    test "returns original config when no matching descriptions exist" do
      config = %{
        "profiles" => [
          %{
            "name" => "default",
            "complex_modifications" => %{
              "rules" => [
                %{"description" => "something else", "manipulators" => [%{"type" => "basic"}]}
              ]
            }
          }
        ]
      }

      new_rules = [
        %{"description" => "karabinex bindings", "manipulators" => [%{"type" => "test"}]}
      ]

      assert KarabinerConfig.replace_rules_in_config(config, new_rules) == config
    end

    test "raises when config missing profiles" do
      config = %{}

      assert_raise RuntimeError, ~r/missing profiles/i, fn ->
        KarabinerConfig.replace_rules_in_config(config, [%{"description" => "x"}])
      end
    end

    test "raises when new rules have no description" do
      config = %{
        "profiles" => [
          %{
            "name" => "default",
            "complex_modifications" => %{
              "rules" => []
            }
          }
        ]
      }
      new_rules = [%{"manipulators" => []}]

      assert_raise RuntimeError, ~r/missing descriptions/i, fn ->
        KarabinerConfig.replace_rules_in_config(config, new_rules)
      end
    end
  end
end
