defmodule Karabinex.Manipulator.InvokeCommand do
  alias Karabinex.{ToManipulator, Manipulator, Chord, Command}

  import Manipulator.DSL

  require Chord

  defstruct [:command]

  def command(:app, arg), do: "open -a '#{arg}'"
  def command(:raycast, arg), do: "open raycast://#{arg}"
  def command(:quit, arg), do: "osascript -e 'quit app \"#{arg}\"'"
  def command(:kill, arg), do: "killall -SIGKILL '#{arg}'"
  def command(:sh, arg), do: arg
  def command(:remap, _arg), do: raise("remapping is not implemented yet")

  def new(%Command{} = cmd), do: %__MODULE__{command: cmd}

  defimpl ToManipulator do
    alias Manipulator.InvokeCommand, as: IC

    def manipulator(%IC{
          command: %Command{kind: kind, arg: arg, chord: chord}
        })
        when Chord.singleton?(chord) do
      chord
      |> Chord.last()
      |> manipulate()
      |> run_shell_command(IC.command(kind, arg))
    end

    def manipulator(%IC{
          command: %Command{kind: kind, arg: arg, chord: chord, repeat: true}
        }) do
      chord
      |> Chord.last()
      |> manipulate()
      |> if_variable(Chord.prefix_var_name(chord))
      |> run_shell_command(IC.command(kind, arg))
    end

    def manipulator(%IC{
          command: %Command{kind: kind, arg: arg, chord: chord, repeat: false}
        }) do
      var_name = Chord.prefix_var_name(chord)

      chord
      |> Chord.last()
      |> manipulate()
      |> if_variable(var_name)
      |> unset_variable(var_name)
      |> run_shell_command(IC.command(kind, arg))
    end
  end
end
