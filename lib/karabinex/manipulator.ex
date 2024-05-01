defmodule Karabinex.Manipulator do
  alias Karabinex.{
    Key,
    Keymap,
    Command,
    Chord
  }

  require Chord

  defmodule EnableKeymap do
    alias Karabinex.{Chord, Manipulator}

    def new(chord) when Chord.singleton?(chord) do
      %{
        type: :basic,
        from: Manipulator.from(Chord.last(chord)),
        to: [
          %{
            set_variable: %{
              name: Chord.var_name(chord),
              value: 1
            }
          }
        ]
      }
    end

    def new(chord) do
      %{
        type: :basic,
        from: Manipulator.from(Chord.last(chord)),
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
              value: 0
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
      }
    end
  end

  defmodule DisableKeymap do
    alias Karabinex.Chord

    def new(chord) do
      %{
        type: :basic,
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
      }
    end
  end

  defmodule CaptureModifier do
    alias Karabinex.Chord

    def new(modifier_key_code, chord) do
      %{
        type: :basic,
        from: %{
          key_code: modifier_key_code
        },
        to: [
          %{
            key_code: modifier_key_code
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
    end
  end

  defmodule InvokeCommand do
    alias Karabinex.{Command, Chord, Manipulator}

    require Chord

    def new(%Command{kind: kind, arg: arg, chord: chord})
        when Chord.singleton?(chord) do
      %{type: :basic, from: Manipulator.from(Chord.last(chord)), to: [command_object(kind, arg)]}
    end

    def new(%Command{kind: kind, arg: arg, chord: chord, opts: opts}) do
      %{
        type: :basic,
        from: Manipulator.from(Chord.last(chord)),
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
  end

  def generate(%Keymap{chord: chord, children: children} = keymap) do
    [
      chord |> EnableKeymap.new(),
      children |> Enum.map(&generate/1),
      keymap |> get_child_modifiers() |> Enum.map(&CaptureModifier.new(&1, chord)),
      chord |> DisableKeymap.new()
    ]
    |> List.flatten()
  end

  def generate(%Command{} = c), do: InvokeCommand.new(c)

  def get_child_modifiers(%Keymap{children: children}) do
    children
    |> Enum.flat_map(fn %{chord: chord} ->
      Chord.last(chord).modifiers
    end)
    |> Enum.uniq()
    |> Enum.flat_map(&["left_#{&1}", "right_#{&1}"])
  end

  def from(%Key{modifiers: []} = key), do: Key.code(key)

  def from(%Key{modifiers: modifiers} = key) do
    Key.code(key)
    |> Map.merge(%{
      modifiers: %{
        mandatory: modifiers
      }
    })
  end
end
