defmodule Karabinex.ChordTest do
  use ExUnit.Case

  alias Karabinex.{Chord, Key}

  require Chord

  describe "new/0" do
    test "creates empty chord" do
      assert %Chord{keys: []} = Chord.new()
    end
  end

  describe "append/2" do
    test "appends key to empty chord" do
      chord = Chord.new() |> Chord.append(Key.new("x"))

      assert length(chord.keys) == 1
      assert hd(chord.keys).code == {:regular, "x"}
    end

    test "appends key to existing chord" do
      chord =
        Chord.new()
        |> Chord.append(Key.new("a"))
        |> Chord.append(Key.new("b"))

      assert length(chord.keys) == 2
      assert Enum.at(chord.keys, 0).code == {:regular, "a"}
      assert Enum.at(chord.keys, 1).code == {:regular, "b"}
    end
  end

  describe "last/1" do
    test "returns last key in chord" do
      chord =
        Chord.new()
        |> Chord.append(Key.new("a"))
        |> Chord.append(Key.new("b"))

      assert Chord.last(chord).code == {:regular, "b"}
    end

    test "returns only key in singleton chord" do
      chord = Chord.new() |> Chord.append(Key.new("x"))

      assert Chord.last(chord).code == {:regular, "x"}
    end
  end

  describe "prefix/1" do
    test "returns chord without last key" do
      chord =
        Chord.new()
        |> Chord.append(Key.new("a"))
        |> Chord.append(Key.new("b"))
        |> Chord.append(Key.new("c"))

      prefix = Chord.prefix(chord)

      assert length(prefix.keys) == 2
      assert Enum.at(prefix.keys, 0).code == {:regular, "a"}
      assert Enum.at(prefix.keys, 1).code == {:regular, "b"}
    end

    test "returns empty chord when prefix of two-key chord" do
      chord =
        Chord.new()
        |> Chord.append(Key.new("a"))
        |> Chord.append(Key.new("b"))

      prefix = Chord.prefix(chord)

      assert length(prefix.keys) == 1
      assert hd(prefix.keys).code == {:regular, "a"}
    end
  end

  describe "var_name/1" do
    test "generates variable name for single key" do
      chord = Chord.new() |> Chord.append(Key.new("x"))

      assert Chord.var_name(chord) == "karabinex_x_map"
    end

    test "generates variable name for multiple keys" do
      chord =
        Chord.new()
        |> Chord.append(Key.new("a"))
        |> Chord.append(Key.new("b"))

      assert Chord.var_name(chord) == "karabinex_a_b_map"
    end

    test "includes modifiers in variable name" do
      chord = Chord.new() |> Chord.append(Key.new("M-x"))

      assert Chord.var_name(chord) =~ "option"
    end
  end

  describe "prefix_var_name/1" do
    test "generates variable name for prefix of chord" do
      chord =
        Chord.new()
        |> Chord.append(Key.new("a"))
        |> Chord.append(Key.new("b"))

      assert Chord.prefix_var_name(chord) == "karabinex_a_map"
    end

    test "works with three-key chord" do
      chord =
        Chord.new()
        |> Chord.append(Key.new("a"))
        |> Chord.append(Key.new("b"))
        |> Chord.append(Key.new("c"))

      assert Chord.prefix_var_name(chord) == "karabinex_a_b_map"
    end
  end

  describe "singleton?/1 guard" do
    test "returns true for single-key chord" do
      chord = Chord.new() |> Chord.append(Key.new("x"))

      assert Chord.singleton?(chord)
    end

    test "returns false for multi-key chord" do
      chord =
        Chord.new()
        |> Chord.append(Key.new("a"))
        |> Chord.append(Key.new("b"))

      refute Chord.singleton?(chord)
    end

    test "raises on empty chord (guard requires non-empty)" do
      chord = Chord.new()

      assert_raise ArgumentError, fn ->
        Chord.singleton?(chord)
      end
    end
  end
end
