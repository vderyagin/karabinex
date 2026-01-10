defmodule Karabinex.KeyTest do
  use ExUnit.Case

  alias Karabinex.Key

  describe "has_modifiers? guard" do
    test "detects plain key" do
      refute Key.has_modifiers?(Key.new("x"))
    end

    test "detects key with single modifier" do
      assert Key.has_modifiers?(Key.new("M-x"))
    end

    test "detects key with multiple modifiers" do
      assert Key.has_modifiers?(Key.new("Meh-x"))
    end
  end

  describe "key definition parsing" do
    test "parses simple keys" do
      assert Key.parse(%Key{}, "x") == %Key{code: {:regular, "x"}}
    end

    test "modifiers: option" do
      assert Key.parse(%Key{}, "M-i") == %Key{
               code: {:regular, "i"},
               modifiers: MapSet.new([:option])
             }

      assert Key.parse(%Key{}, "⌥-i") == %Key{
               code: {:regular, "i"},
               modifiers: MapSet.new([:option])
             }
    end

    test "modifiers: command" do
      assert Key.parse(%Key{}, "⌘-i") == %Key{
               code: {:regular, "i"},
               modifiers: MapSet.new([:command])
             }
    end

    test "modifiers: control" do
      assert Key.parse(%Key{}, "C-q") == %Key{
               code: {:regular, "q"},
               modifiers: MapSet.new([:control])
             }

      assert Key.parse(%Key{}, "^-q") == %Key{
               code: {:regular, "q"},
               modifiers: MapSet.new([:control])
             }
    end

    test "modifiers: shift" do
      assert Key.parse(%Key{}, "S-c") == %Key{
               code: {:regular, "c"},
               modifiers: MapSet.new([:shift])
             }
    end

    test "modifiers: meh" do
      %Key{code: {:regular, "o"}, modifiers: modifiers} = Key.parse(%Key{}, "Meh-o")

      assert MapSet.equal?(MapSet.new([:shift, :option, :control]), modifiers)
    end

    test "modifiers: hyper" do
      %Key{code: {:regular, "b"}, modifiers: modifiers} = Key.parse(%Key{}, "H-b")

      assert Key.parse(%Key{}, "H-b") == Key.parse(%Key{}, "M-C-S-⌘-b")
      assert Key.parse(%Key{}, "H-b") == Key.parse(%Key{}, "✦-b")

      assert MapSet.equal?(MapSet.new([:shift, :option, :control, :command]), modifiers)
    end
  end
end
