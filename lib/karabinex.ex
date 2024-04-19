# TODO: split into different types
defmodule Karabinex do
  defmodule Key do
    defstruct raw: nil,
              code: nil,
              modifiers: %{
                command: false,
                shift: false,
                option: false,
                control: false
              }

    @type modifier ::
            :command
            | :shift
            | :option
            | :control

    @type key_code_type ::
            :regular
            | :consumer
            | :pointer

    @type code :: {key_code_type(), String.t()}

    @type t :: %__MODULE__{
            raw: String.t(),
            code: code(),
            modifiers: %{modifier() => boolean()}
          }

    def new(key) do
      %__MODULE__{raw: key}
      |> parse(key)
    end

    def set_code(%__MODULE__{code: nil} = key, code) do
      %{key | code: code}
    end

    def set_modifier(%__MODULE__{modifiers: %{command: false} = mods} = key, :command) do
      %{key | modifiers: %{mods | command: true}}
    end

    def set_modifier(%__MODULE__{modifiers: %{shift: false} = mods} = key, :shift) do
      %{key | modifiers: %{mods | shift: true}}
    end

    def set_modifier(%__MODULE__{modifiers: %{option: false} = mods} = key, :option) do
      %{key | modifiers: %{mods | option: true}}
    end

    def set_modifier(%__MODULE__{modifiers: %{control: false} = mods} = key, :control) do
      %{key | modifiers: %{mods | control: true}}
    end

    def set_modifiers(%__MODULE__{} = key, [first | rest]) do
      key
      |> set_modifier(first)
      |> set_modifiers(rest)
    end

    def set_modifiers(%__MODULE__{} = key, []), do: key

    def parse(%__MODULE__{} = key, "✦-" <> rest) do
      key
      |> set_modifiers([:command, :shift, :option, :control])
      |> parse(rest)
    end

    def parse(%__MODULE__{} = key, "⌘-" <> rest) do
      key
      |> set_modifier(:command)
      |> parse(rest)
    end

    def parse(%__MODULE__{} = key, "⌥-" <> rest) do
      key
      |> set_modifier(:option)
      |> parse(rest)
    end

    def parse(%__MODULE__{} = key, "C-" <> rest) do
      key
      |> set_modifier(:control)
      |> parse(rest)
    end

    def parse(%__MODULE__{} = key, "S-" <> rest) do
      key
      |> set_modifier(:shift)
      |> parse(rest)
    end

    def parse(%__MODULE__{raw: raw} = key, key_code) do
      # TODO: fix this, it loads data from json on every call
      codes = key_codes()

      code_type =
        cond do
          MapSet.member?(codes[:regular], key_code) -> :regular
          MapSet.member?(codes[:consumer], key_code) -> :consumer
          MapSet.member?(codes[:pointer], key_code) -> :pointer
          true -> raise "key code not recognized: #{raw}"
        end

      key
      |> set_code({code_type, key_code})
    end

    def key_codes do
      :code.priv_dir(:karabinex)
      |> Path.join("/simple_modifications.json")
      |> File.read!()
      |> Jason.decode!(keys: :atoms)
      |> Enum.reduce(%{}, fn
        %{data: [%{key_code: code}]}, acc ->
          Map.update(acc, :regular, MapSet.new(), &MapSet.put(&1, code))

        %{data: [%{consumer_key_code: code}]}, acc ->
          Map.update(acc, :consumer, MapSet.new(), &MapSet.put(&1, code))

        %{data: [%{pointing_button: code}]}, acc ->
          Map.update(acc, :pointer, MapSet.new(), &MapSet.put(&1, code))

        _, acc ->
          acc
      end)
    end

    def from_object(%__MODULE__{code: {:regular, code}, modifiers: modifiers}) do
      mandatory_modifiers =
        modifiers
        |> Enum.filter(fn {_k, v} -> v end)
        |> Enum.map(fn {k, _v} -> k end)

      %{
        from:
          %{
            key_code: code
          }
          |> Map.merge(
            if Enum.empty?(mandatory_modifiers) do
              %{}
            else
              %{
                modifiers: %{
                  mandatory: mandatory_modifiers
                }
              }
            end
          )
      }
    end
  end

  defmodule Command do
    @type kind ::
            :app
            | :quit
            | :sh
            | :remap
            | :raycast

    @type spec ::
            {kind(), String.t()}
            | {kind(), String.t(), [option()]}

    @type option ::
            {:if, any()}
            | {:repeat, :key | :keymap}

    defstruct [:kind, :arg, :opts, :key, :prefix]

    def new(kind, arg, key, prefix, opts \\ []) do
      %__MODULE__{
        kind: kind,
        arg: arg,
        key: key,
        prefix: prefix,
        opts: opts
      }
    end
  end

  defmodule Keymap do
    @type spec :: %{String.t() => Command.spec() | spec()}

    defstruct [:key, prefix: [], commands: []]

    def new(key, prefix, commands) do
      %__MODULE__{
        key: key,
        prefix: prefix,
        commands: commands
      }
    end
  end

  defmodule Manipulator do
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
        # TODO: implement different repeats
        # TODO: implement conditionals
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
      |> Map.merge(Key.new(key) |> Key.from_object())
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
      |> Map.merge(Key.new(key) |> Key.from_object())
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

    # TODO: implement remapping
    def command_object(:app, arg) do
      command_object(:sh, "open -a '#{arg}'")
    end

    def command_object(:raycast, arg) do
      command_object(:sh, "open raycast://#{arg}")
    end

    def command_object(:quit, arg) do
      command_object(:sh, "osascript -e 'quit app \"#{arg}\"'")
    end

    def command_object(:sh, arg) do
      %{shell_command: arg}
    end

    def disable_keymap(key, prefix) do
      @base_manipulator
      |> Map.merge(%{
        from: %{
          any: :key_code
        },
        to: [
          %{
            set_variable: %{
              name: prefix_var_name(prefix ++ [key]),
              value: 0
            }
          }
        ],
        conditions: [
          %{
            type: :variable_if,
            name: prefix_var_name(prefix ++ [key]),
            value: 1
          }
        ]
      })
    end

    def prefix_var_name(keys) do
      (Enum.join(keys, "_") <> "_keymap")
      |> String.replace("✦", "hyper")
    end
  end

  defmodule Config do
    def parse_definitions(defs, prefix \\ []) do
      defs
      |> Enum.map(&parse_definition(&1, prefix))
    end

    def parse_definition({key, %{} = keymap_spec}, prefix) do
      Keymap.new(key, prefix, parse_definitions(keymap_spec, prefix ++ [key]))
    end

    def parse_definition({key, {kind, arg}}, prefix) do
      parse_definition({key, {kind, arg, []}}, prefix)
    end

    def parse_definition({key, {kind, arg, opts}}, prefix) do
      Command.new(kind, arg, key, prefix, opts)
    end
  end

  @spec definitions :: Keymap.spec()
  def definitions do
    %{
      "✦-x" => %{
        "e" => {:app, "Emacs"},
        "✦-e" => {:sh, "PATH=/opt/homebrew/bin:$PATH emacsclient -c -a '' &"},
        "c" => {:app, "Brave Browser"},
        "s" => {:app, "Slack"},
        "a" => {:app, "Anki"},
        "b" => {:app, "Books"},
        "t" => {:app, "Telegram Desktop"},
        "d" => {:app, "Dash"},
        "m" => {:sh, "pgrep mpv && open -a mpv || true"},
        "r" => %{
          "c" => {:raycast, "extensions/raycast/raycast/confetti", repeat: :key},
          "g" => {:raycast, "extensions/josephschmitt/gif-search/search"},
          "t" => {:raycast, "extensions/gebeto/translate/translate"},
          "b" => {:raycast, "extensions/nhojb/brew/search"},
          "e" => {:raycast, "extensions/raycast/emoji-symbols/search-emoji-symbols"}
        }
      },
      "✦-k" => %{
        "c" => {:quit, "Brave Browser"},
        "s" => {:quit, "Slack"},
        "✦-s" => {:sh, "killall -9 Slack"},
        "✦-e" => {:sh, "killall -9 Emacs"},
        "a" => {:quit, "Anki"},
        "b" => {:quit, "Books"},
        "t" => {:quit, "Telegram Desktop"},
        "d" => {:quit, "Dash"}
      }
    }
  end

  def test do
    definitions()
    |> Config.parse_definitions()
    |> Enum.flat_map(&Manipulator.generate/1)
    |> Jason.encode!(pretty: true)
    |> IO.puts()
  end

  def json do
    %{
      title: "Nested Emacs-like bindings",
      rules: [
        %{
          description: "Nested Emacs-like bindings",
          manipulators:
            definitions()
            |> Config.parse_definitions()
            |> Enum.flat_map(&Manipulator.generate/1)
        }
      ]
    }
    |> Jason.encode!(pretty: true)
  end

  def write_config do
    File.write!("./karabiner.json", json())
  end
end
