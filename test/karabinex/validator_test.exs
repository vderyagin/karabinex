defmodule Karabinex.ValidatorTest do
  use ExUnit.Case, async: true

  alias Karabinex.Validator

  describe "validate!/1 with valid config" do
    test "passes valid simple config" do
      input = %{"M-a": {:app, "Emacs"}}
      assert Validator.validate!(input) == input
    end

    test "passes valid nested config" do
      input = %{
        "M-x": %{
          a: {:app, "Emacs"},
          b: {:sh, "echo hello"}
        }
      }

      assert Validator.validate!(input) == input
    end

    test "passes config with repeat: :key at nested level" do
      input = %{
        "M-x": %{
          c: {:raycast, "confetti", repeat: :key}
        }
      }

      assert Validator.validate!(input) == input
    end

    test "passes config with repeat: :keymap at nested level" do
      input = %{
        "M-x": %{
          c: {:raycast, "confetti", repeat: :keymap}
        }
      }

      assert Validator.validate!(input) == input
    end

    test "passes config with __hook__ at nested level" do
      input = %{
        "M-x": %{
          :__hook__ => {:raycast, "confetti"},
          c: {:app, "Emacs"}
        }
      }

      assert Validator.validate!(input) == input
    end
  end

  describe "validate!/1 rejects top-level repeat" do
    test "raises on repeat: :key at top level" do
      input = %{"M-a": {:app, "Emacs", repeat: :key}}

      assert_raise RuntimeError, ~r/repeat.*cannot be used at top level/i, fn ->
        Validator.validate!(input)
      end
    end

    test "raises on repeat: :keymap at top level" do
      input = %{"M-a": {:app, "Emacs", repeat: :keymap}}

      assert_raise RuntimeError, ~r/repeat.*cannot be used at top level/i, fn ->
        Validator.validate!(input)
      end
    end
  end

  describe "validate!/1 rejects top-level keys without modifiers" do
    test "raises on top-level command without modifiers" do
      input = %{a: {:app, "Emacs"}}

      assert_raise RuntimeError, ~r/top-level key.*modifiers/i, fn ->
        Validator.validate!(input)
      end
    end

    test "raises on top-level keymap without modifiers" do
      input = %{a: %{b: {:app, "Emacs"}}}

      assert_raise RuntimeError, ~r/top-level key.*modifiers/i, fn ->
        Validator.validate!(input)
      end
    end
  end

  describe "validate!/1 rejects duplicate keys" do
    test "raises on duplicate keys with different modifier order" do
      input = %{"⌘-⌥-x": {:app, "Emacs"}, "⌥-⌘-x": {:app, "Other"}}

      assert_raise RuntimeError, ~r/duplicate keys/i, fn ->
        Validator.validate!(input)
      end
    end

    test "raises on duplicate keys with different modifier notation" do
      input = %{"⌥-x": {:app, "Emacs"}, "M-x": {:app, "Other"}}

      assert_raise RuntimeError, ~r/duplicate keys/i, fn ->
        Validator.validate!(input)
      end
    end

    test "raises on duplicates within nested keymap" do
      input = %{
        "M-r": %{
          "⌘-⌥-a": {:app, "Emacs"},
          "⌥-⌘-a": {:app, "Other"}
        }
      }

      assert_raise RuntimeError, ~r/duplicate keys/i, fn ->
        Validator.validate!(input)
      end
    end
  end

  describe "validate!/1 rejects empty keymaps" do
    test "raises on empty top-level config" do
      assert_raise RuntimeError, ~r/cannot be empty/i, fn ->
        Validator.validate!(%{})
      end
    end

    test "raises on empty nested keymap" do
      input = %{"M-r": %{}}

      assert_raise RuntimeError, ~r/empty keymap/i, fn ->
        Validator.validate!(input)
      end
    end
  end

  describe "validate!/1 rejects unknown command types" do
    test "raises on unknown command type" do
      input = %{"M-a": {:unknown, "arg"}}

      assert_raise RuntimeError, ~r/unknown command type.*:unknown/i, fn ->
        Validator.validate!(input)
      end
    end

    test "raises on typo in command type" do
      input = %{"M-a": {:ap, "Emacs"}}

      assert_raise RuntimeError, ~r/unknown command type.*:ap/i, fn ->
        Validator.validate!(input)
      end
    end
  end

  describe "validate!/1 rejects unknown options" do
    test "raises on unknown option" do
      input = %{"M-x": %{a: {:app, "Emacs", foo: :bar}}}

      assert_raise RuntimeError, ~r/unknown option.*:foo/i, fn ->
        Validator.validate!(input)
      end
    end

    test "raises on typo in option" do
      input = %{"M-x": %{a: {:app, "Emacs", repat: :keymap}}}

      assert_raise RuntimeError, ~r/unknown option.*:repat/i, fn ->
        Validator.validate!(input)
      end
    end
  end

  describe "validate!/1 rejects __hook__ at top level" do
    test "raises on __hook__ at top level" do
      input = %{:__hook__ => {:raycast, "confetti"}, "M-a": {:app, "Emacs"}}

      assert_raise RuntimeError, ~r/__hook__.*top level/i, fn ->
        Validator.validate!(input)
      end
    end
  end

  describe "validate!/1 rejects hooks with options" do
    test "raises when hook has options" do
      input = %{
        "M-x": %{
          :__hook__ => {:raycast, "confetti", repeat: :keymap},
          c: {:app, "Emacs"}
        }
      }

      assert_raise RuntimeError, ~r/hook cannot have options/i, fn ->
        Validator.validate!(input)
      end
    end
  end

  describe "validate!/1 validates at all depths" do
    test "catches errors in deeply nested config" do
      input = %{
        "M-a": %{
          b: %{
            c: %{
              d: {:unknown_type, "arg"}
            }
          }
        }
      }

      assert_raise RuntimeError, ~r/unknown command type/i, fn ->
        Validator.validate!(input)
      end
    end
  end
end
