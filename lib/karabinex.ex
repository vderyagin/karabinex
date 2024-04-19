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

    def parse(%__MODULE__{} = key, key_code) do
      key
      |> set_code(key_code)
    end
  end

  defmodule Manipulator do
    @base_manipulator %{
      type: "basic"
    }

    @base_key %{
      modifiers: %{
        mandatory: []
      }
    }

    def enamble_keymap(key) do
      @base_manipulator
      |> Map.merge(%{
        from: %{},
        to: [
          %{
            set_variable: %{
              name: prefix_var_name(key),
              value: 1
            }
          }
        ]
      })
    end

    def disable_keymap(key) do
      @base_manipulator
      |> Map.merge(%{
        from: %{
          any: "key_code"
        },
        to: [
          %{
            set_variable: %{
              name: prefix_var_name(key),
              value: 0
            }
          }
        ],
        conditions: [
          %{
            type: "variable_if",
            name: prefix_var_name(key),
            value: 1
          }
        ]
      })
    end

    def prefix_var_name(key) do
      key
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

    defstruct [:kind, :arg, :opts]

    def new(kind, arg, opts \\ []), do: %__MODULE__{kind: kind, arg: arg, opts: opts}
  end

  defmodule Keymap do
    @type spec :: %{String.t() => Command.spec() | spec()}

    defstruct [:key]

    def new(key), do: %__MODULE__{key: key}
  end

  defmodule Config do
    def parse_definitions(defs) do
      defs
      |> Enum.flat_map(&parse_definition/1)
    end

    def parse_definition({key, %{} = keymap_spec}) do
      [
        Keymap.new(key)
        | parse_definitions(keymap_spec)
      ]
    end

    def parse_definition({key, {kind, arg}}) do
      parse_definition({key, {kind, arg, []}})
    end

    def parse_definition({key, {kind, arg, opts}}) do
      [Command.new(kind, arg, opts)]
    end
  end

  @spec definitions :: Keymap.spec()
  def definitions do
    %{
      "✦-x" => %{
        "c" => {:app, "Brave Browser"},
        "s" => {:app, "Slack"},
        "a" => {:app, "Anki"},
        "b" => {:app, "Books"},
        "d" => {:app, "Dash"},
        "m" => {:sh, "pgrep mpv && open -a mpv || true"},
        "r" => %{
          "c" => {:raycast, "extensions/raycast/raycast/confetti", repeat: :key},
          "g" => {:raycast, "extensions/josephschmitt/gif-search/search"},
          "t" => {:raycast, "extensions/gebeto/translate/translate"}
        }
      },
      "✦-k" => %{
        "c" => {:quit, "Brave Browser"},
        "s" => {:quit, "Slack"},
        "S" => {:sh, "killall -9 Slack"},
        "a" => {:quit, "Anki"},
        "b" => {:quit, "Books"}
      }
    }
  end
end
