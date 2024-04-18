defmodule Karabinex do
  @type command_kind :: :app | :quit | :sh | :raycast
  @type command :: {command_kind(), String.t()}
  @type keymap :: %{String.t() => command() | keymap()}

  @spec definitions :: %{String.t() => keymap()}
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
          "c" => {:raycast, "extensions/raycast/raycast/confetti"},
          "g" => {:raycast, "extensions/josephschmitt/gif-search/search"}
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
