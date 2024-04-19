defmodule Karabinex do
  defmodule Command do
    @type kind ::
            :app
            | :quit
            | :sh
            | :raycast

    @type spec ::
            {kind(), String.t()}
            | {kind(), String.t(), [option()]}

    @type option ::
            {:if, any()}
            | {:repeat, :key | :keymap}
  end

  @type keymap :: %{String.t() => Command.spec() | keymap()}

  @spec definitions :: keymap()
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
