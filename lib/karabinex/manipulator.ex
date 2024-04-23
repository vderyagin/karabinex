defmodule Karabinex.Manipulator do
  alias Karabinex.{
    Key,
    Keymap,
    Command
  }

  def generate(%Keymap{key: key, prefix: prefix, commands: children}) do
    [
      enable_keymap(key, prefix),
      children |> Enum.map(&generate/1),
      children |> capture_modifiers(prefix ++ [key]),
      disable_keymap(key, prefix)
    ]
    |> List.flatten()
  end

  def generate(%Command{kind: kind, arg: arg, key: key, prefix: []}) do
    make_manipulator(%{
      from: from(key),
      to: [command_object(kind, arg)]
    })
  end

  def generate(%Command{kind: kind, arg: arg, key: key, prefix: prefix, opts: opts}) do
    prefix_var = prefix_var_name(prefix)

    make_manipulator(%{
      from: from(key),
      to:
        if opts[:repeat] do
          [command_object(kind, arg)]
        else
          [
            command_object(kind, arg),
            %{
              set_variable: %{
                name: prefix_var,
                value: 0
              }
            }
          ]
        end,
      conditions: [
        %{
          type: :variable_if,
          name: prefix_var,
          value: 1
        }
      ]
    })
  end

  def enable_keymap(key, []) do
    make_manipulator(%{
      from: from(key),
      to: [
        %{
          set_variable: %{
            name: prefix_var_name([key]),
            value: 1
          }
        }
      ]
    })
  end

  def enable_keymap(key, prefix) do
    make_manipulator(%{
      from: from(key),
      to: [
        %{
          set_variable: %{
            name: prefix_var_name(prefix),
            value: 0
          }
        },
        %{
          set_variable: %{
            name: prefix_var_name(prefix ++ [key]),
            value: 1
          }
        }
      ],
      conditions: [
        %{
          type: :variable_if,
          name: prefix_var_name(prefix),
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

  def capture_modifiers(commands, map_prefix) do
    commands
    |> Enum.flat_map(fn %{key: %Key{modifiers: modifiers}} ->
      modifiers
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
          conditions: [
            %{
              type: :variable_if,
              name: prefix_var_name(map_prefix),
              value: 1
            }
          ]
        }
      )
    end)
    |> Enum.map(&make_manipulator/1)
  end

  def disable_keymap(key, prefix) do
    var_name = prefix_var_name(prefix ++ [key])

    make_manipulator(%{
      from: %{
        any: :key_code
      },
      to: [
        %{
          set_variable: %{
            name: var_name,
            value: 0
          }
        }
      ],
      conditions: [
        %{
          type: :variable_if,
          name: var_name,
          value: 1
        }
      ]
    })
  end

  def prefix_var_name(keys) do
    keys
    |> Enum.map(&Map.get(&1, :raw))
    |> Enum.join("_")
    |> Kernel.<>("_keymap")
    |> String.replace("✦", "hyper")
    |> String.replace("⌥", "option")
    |> String.replace("⌘", "command")
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
