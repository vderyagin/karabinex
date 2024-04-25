defmodule Karabinex.Manipulator do
  alias Karabinex.{
    Key,
    Keymap,
    Command,
    Chord
  }

  require Chord

  def generate(%Keymap{chord: chord, children: children}) do
    [
      chord |> enable_keymap(),
      children |> Enum.map(&generate/1),
      children |> capture_modifiers(chord),
      chord |> disable_keymap()
    ]
    |> List.flatten()
  end

  def generate(%Command{kind: kind, arg: arg, chord: chord})
      when Chord.singleton?(chord) do
    make_manipulator(%{
      from: from(Chord.last(chord)),
      to: [command_object(kind, arg)]
    })
  end

  def generate(%Command{kind: kind, arg: arg, chord: chord, opts: opts}) do
    make_manipulator(%{
      from: from(Chord.last(chord)),
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
    })
  end

  def enable_keymap(chord) when Chord.singleton?(chord) do
    make_manipulator(%{
      from: from(Chord.last(chord)),
      to: [
        %{
          set_variable: %{
            name: Chord.var_name(chord),
            value: 1
          }
        }
      ]
    })
  end

  def enable_keymap(chord) do
    make_manipulator(%{
      from: from(Chord.last(chord)),
      to: [
        %{
          set_variable: %{
            name: Chord.var_name(chord),
            value: 1
          }
        },
        %{
          set_variable: %{
            name: Chord.prefix_var_name(chord),
            value: 1
          }
        }
      ],
      conditions: [
        %{
          type: :variable_if,
          name: Chord.prefix_var_name(chord),
          value: 1
        }
      ]
    })
  end

  def command_object(:app, arg) do
    command_object(:sh, "open -a '#{arg}'")
  end

  def command_object(:raycast, arg) do
    command_object(:sh, "open raycast://#{arg}")
  end

  def command_object(:quit, arg) do
    command_object(:sh, "osascript -e 'quit app \"#{arg}\"'")
  end

  def command_object(:kill, arg) do
    command_object(:sh, "killall -SIGKILL '#{arg}'")
  end

  def command_object(:sh, arg) do
    %{shell_command: arg}
  end

  def capture_modifiers(commands, chord) do
    commands
    |> Enum.flat_map(fn %{chord: chord} ->
      Chord.last(chord).modifiers
    end)
    |> Enum.uniq()
    |> Enum.flat_map(fn modifier ->
      [:left, :right]
      |> Enum.map(
        &%{
          from: %{
            key_code: "#{&1}_#{modifier}"
          },
          to: [
            %{
              key_code: "#{&1}_#{modifier}"
            }
          ],
          to_after_key_up: [
            %{
              set_variable: %{
                name: Chord.var_name(chord),
                value: 0
              }
            }
          ],
          conditions: [
            %{
              type: :variable_if,
              name: Chord.var_name(chord),
              value: 1
            }
          ]
        }
      )
    end)
    |> Enum.map(&make_manipulator/1)
  end

  def disable_keymap(chord) do
    make_manipulator(%{
      from: %{
        any: :key_code
      },
      to: [
        %{
          set_variable: %{
            name: Chord.var_name(chord),
            value: 0
          }
        }
      ],
      conditions: [
        %{
          type: :variable_if,
          name: Chord.var_name(chord),
          value: 1
        }
      ]
    })
  end

  defp make_manipulator(properties), do: Map.merge(%{type: :basic}, properties)

  defp from(%Key{modifiers: []} = key), do: Key.code(key)

  defp from(%Key{modifiers: modifiers} = key) do
    Key.code(key)
    |> Map.merge(%{
      modifiers: %{
        mandatory: modifiers
      }
    })
  end
end
