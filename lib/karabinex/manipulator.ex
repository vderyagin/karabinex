defmodule Karabinex.Manipulator do
  alias Karabinex.{
    Key,
    Keymap,
    Command
  }

  def virtual_modifiers(%Key{modifiers: modifiers}) do
    [:control, :shift, :command, :option]
    |> Enum.map(
      &%{
        type: :variable_if,
        name: &1,
        value: if(&1 in modifiers, do: 1, else: 0)
      }
    )
  end

  def concrete_modifiers(%Key{modifiers: []}), do: %{}

  def concrete_modifiers(%Key{modifiers: modifiers}) do
    %{
      modifiers: %{
        mandatory: modifiers
      }
    }
  end

  def generate(%Keymap{key: key, prefix: prefix, commands: commands}) do
    [enable_keymap(key, prefix)] ++
      capture_modifiers(commands, prefix ++ [key]) ++
      Enum.flat_map(commands, &generate/1) ++
      [disable_keymap(key, prefix)]
  end

  def generate(%Command{kind: kind, arg: arg, key: key, prefix: []}) do
    make_manipulator(%{
      from:
        Key.code(key)
        |> Map.merge(concrete_modifiers(key)),
      to: [
        command_object(kind, arg)
      ]
    })
    |> List.wrap()
  end

  def generate(%Command{kind: kind, arg: arg, key: key, prefix: prefix, opts: opts}) do
    make_manipulator(%{
      from: Key.code(key),
      to:
        if opts[:repeat] do
          [command_object(kind, arg)]
        else
          [
            command_object(kind, arg),
            %{
              set_variable: %{
                name: prefix_var_name(prefix),
                value: 0
              }
            }
          ]
        end,
      conditions:
        virtual_modifiers(key) ++
          [
            %{
              type: :variable_if,
              name: prefix_var_name(prefix),
              value: 1
            }
          ]
    })
    |> List.wrap()
  end

  def enable_keymap(key, []) do
    make_manipulator(%{
      from:
        Key.code(key)
        |> Map.merge(concrete_modifiers(key)),
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
      from: Key.code(key),
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
      conditions:
        virtual_modifiers(key) ++
          [
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
    |> Enum.reduce([], fn
      %{key: %Key{modifiers: modifiers}}, memo ->
        modifiers ++ memo

      _, memo ->
        memo
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
              set_variable: %{
                name: modifier,
                value: 1
              }
            }
          ],
          to_after_key_up: [
            %{
              set_variable: %{
                name: modifier,
                value: 0
              }
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
end
