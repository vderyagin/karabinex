defmodule Karabinex.Manipulator.InvokeCommand do
  alias Karabinex.{Manipulator, Chord, Command}

  require Chord

  def new(%Command{kind: kind, arg: arg, chord: chord})
      when Chord.singleton?(chord) do
    %{
      type: :basic,
      from: Manipulator.make_from(Chord.last(chord)),
      to: [command_object(kind, arg)]
    }
  end

  def new(%Command{kind: kind, arg: arg, chord: chord, opts: opts}) do
    %{
      type: :basic,
      from: Manipulator.make_from(Chord.last(chord)),
      to:
        if opts[:repeat] do
          [command_object(kind, arg)]
        else
          [
            command_object(kind, arg),
            %{
              set_variable: %{
                name: Chord.prefix_var_name(chord),
                value: 0
              }
            }
          ]
        end,
      conditions: [
        %{
          type: :variable_if,
          name: Chord.prefix_var_name(chord),
          value: 1
        }
      ]
    }
  end

  defp command_object(:app, arg) do
    command_object(:sh, "open -a '#{arg}'")
  end

  defp command_object(:raycast, arg) do
    command_object(:sh, "open raycast://#{arg}")
  end

  defp command_object(:quit, arg) do
    command_object(:sh, "osascript -e 'quit app \"#{arg}\"'")
  end

  defp command_object(:kill, arg) do
    command_object(:sh, "killall -SIGKILL '#{arg}'")
  end

  defp command_object(:sh, arg) do
    %{shell_command: arg}
  end
end
