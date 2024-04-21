defmodule Karabinex do
  alias Karabinex.{Keymap, Config, Manipulator}

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
    {:ok, _} = Application.ensure_all_started(:karabinex)
    File.write!("./karabiner.json", json())
  end
end
