defmodule Karabinex.Manipulator do
  alias Karabinex.{
    Key,
    Keymap,
    Command
  }

  @base_manipulator %{
    type: :basic
  }

  def generate(%Keymap{key: key, prefix: prefix, commands: commands}) do
    [
      enable_keymap(key, prefix)
      | commands |> Enum.flat_map(&generate/1)
    ] ++ [disable_keymap(key, prefix)]
  end

  def generate(%Command{kind: kind, arg: arg, key: key, prefix: prefix, opts: opts}) do
    @base_manipulator
    |> Map.merge(Key.new(key) |> Key.from_object())
    |> Map.merge(%{
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
      conditions: [
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
    @base_manipulator
    |> Map.merge(Key.from_object(key))
    |> Map.merge(%{
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
    @base_manipulator
    |> Map.merge(Key.from_object(key))
    |> Map.merge(%{
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

  def disable_keymap(key, prefix) do
    var_name = prefix_var_name(prefix ++ [key])

    @base_manipulator
    |> Map.merge(%{
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
end
