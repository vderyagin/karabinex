defmodule Karabinex.KeyTest do
  use ExUnit.Case

  alias Karabinex.Key

  describe "key definition parsing" do
    test "parses simple keys" do
      assert Key.parse(%Key{}, "x") == %Key{code: {:regular, "x"}, modifiers: []}
    end

    test "modifiers: option" do
      assert Key.parse(%Key{}, "M-i") == %Key{code: {:regular, "i"}, modifiers: [:option]}
      assert Key.parse(%Key{}, "⌥-i") == %Key{code: {:regular, "i"}, modifiers: [:option]}
    end

    test "modifiers: command" do
      assert Key.parse(%Key{}, "⌘-i") == %Key{code: {:regular, "i"}, modifiers: [:command]}
    end

    test "modifiers: control" do
      assert Key.parse(%Key{}, "C-q") == %Key{code: {:regular, "q"}, modifiers: [:control]}
      assert Key.parse(%Key{}, "^-q") == %Key{code: {:regular, "q"}, modifiers: [:control]}
    end

    test "modifiers: shift" do
      assert Key.parse(%Key{}, "S-c") == %Key{code: {:regular, "c"}, modifiers: [:shift]}
    end

    test "modifiers: meh" do
      %Key{code: {:regular, "o"}, modifiers: modifiers} = Key.parse(%Key{}, "Meh-o")

      assert :shift in modifiers
      assert :option in modifiers
      assert :control in modifiers
    end

    test "modifiers: hyper" do
      %Key{code: {:regular, "b"}, modifiers: modifiers} = Key.parse(%Key{}, "H-b")

      assert Key.parse(%Key{}, "H-b") == Key.parse(%Key{}, "✦-b")

      assert :shift in modifiers
      assert :option in modifiers
      assert :control in modifiers
      assert :command in modifiers
    end
  end
end
