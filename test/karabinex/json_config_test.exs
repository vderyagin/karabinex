defmodule Karabinex.JsonConfigTest do
  use ExUnit.Case

  alias Karabinex.JsonConfig

  describe "parse_map!/1" do
    test "parses command object with sh" do
      input = %{
        "Meh-x" => %{
          "sh" => "echo lol"
        }
      }

      assert JsonConfig.parse_map!(input) == %{
               "Meh-x" => {:sh, "echo lol"}
             }
    end

    test "parses nested keymaps" do
      input = %{
        "Meh-x" => %{
          "r" => %{
            "g" => %{
              "raycast" => "foo/bar"
            }
          }
        }
      }

      assert JsonConfig.parse_map!(input) == %{
               "Meh-x" => %{
                 "r" => %{
                   "g" => {:raycast, "foo/bar"}
                 }
               }
             }
    end

    test "parses repeat key" do
      input = %{
        "Meh-x" => %{
          "raycast" => "foo/bar",
          "repeat" => "key"
        }
      }

      assert JsonConfig.parse_map!(input) == %{
               "Meh-x" => {:raycast, "foo/bar", [repeat: :key]}
             }
    end

    test "parses repeat keymap" do
      input = %{
        "Meh-x" => %{
          "raycast" => "foo/bar",
          "repeat" => "keymap"
        }
      }

      assert JsonConfig.parse_map!(input) == %{
               "Meh-x" => {:raycast, "foo/bar", [repeat: :keymap]}
             }
    end

    test "raises on multiple command keys" do
      input = %{
        "Meh-x" => %{
          "sh" => "echo lol",
          "app" => "Emacs"
        }
      }

      assert_raise RuntimeError, ~r/Multiple command keys/, fn ->
        JsonConfig.parse_map!(input)
      end
    end

    test "raises on unknown command fields" do
      input = %{
        "Meh-x" => %{
          "sh" => "echo lol",
          "extra" => "nope"
        }
      }

      assert_raise RuntimeError, ~r/Unknown command keys/, fn ->
        JsonConfig.parse_map!(input)
      end
    end

    test "raises on invalid repeat" do
      input = %{
        "Meh-x" => %{
          "raycast" => "foo/bar",
          "repeat" => "nope"
        }
      }

      assert_raise RuntimeError, ~r/Invalid repeat value/, fn ->
        JsonConfig.parse_map!(input)
      end
    end

    test "raises on reserved key in keymap" do
      input = %{
        "repeat" => %{
          "sh" => "echo lol"
        }
      }

      assert_raise RuntimeError, ~r/Reserved key/, fn ->
        JsonConfig.parse_map!(input)
      end
    end

    test "raises when input is not an object" do
      input = []

      assert_raise RuntimeError, ~r/object/, fn ->
        JsonConfig.parse_map!(input)
      end
    end
  end

  describe "parse_json!/1" do
    test "parses JSON string" do
      json = ~s({"Meh-x":{"sh":"echo lol"}})

      assert JsonConfig.parse_json!(json) == %{
               "Meh-x" => {:sh, "echo lol"}
             }
    end
  end
end
