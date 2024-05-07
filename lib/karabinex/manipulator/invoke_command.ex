defmodule Karabinex.Manipulator.InvokeCommand do
  alias Karabinex.{Manipulator, Chord, Command}

  import Manipulator.DSL

  require Chord

  def new(%Command{kind: kind, arg: arg, chord: chord})
      when Chord.singleton?(chord) do
    Chord.last(chord)
    |> manipulate()
    |> run_shell_command(command(kind, arg))
  end

  def new(%Command{kind: kind, arg: arg, chord: chord, repeat: true}) do
    Chord.last(chord)
    |> manipulate()
    |> if_variable(Chord.prefix_var_name(chord))
    |> run_shell_command(command(kind, arg))
  end

  def new(%Command{kind: kind, arg: arg, chord: chord, repeat: false}) do
    var_name = Chord.prefix_var_name(chord)

    Chord.last(chord)
    |> manipulate()
    |> if_variable(var_name)
    |> unset_variable(var_name)
    |> run_shell_command(command(kind, arg))
  end

  def command(:app, arg), do: "open -a '#{arg}'"
  def command(:raycast, arg), do: "open raycast://#{arg}"
  def command(:quit, arg), do: "osascript -e 'quit app \"#{arg}\"'"
  def command(:kill, arg), do: "killall -SIGKILL '#{arg}'"
  def command(:sh, arg), do: arg
end
