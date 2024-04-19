defmodule Karabinex do
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
      "H-x" => %{
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
      "H-k" => %{
        "c" => {:quit, "Brave Browser"},
        "s" => {:quit, "Slack"},
        "S" => {:sh, "killall -9 Slack"},
        "a" => {:quit, "Anki"},
        "b" => {:quit, "Books"}
      }
    }
  end
end
