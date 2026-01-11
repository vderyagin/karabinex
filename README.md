# Karabinex

An Elixir DSL for generating [Karabiner-Elements](https://karabiner-elements.pqrs.org/) complex modifications configuration.

## Usage

1. Clone the repository
2. Run `mix deps.get` to install dependencies
3. Edit `rules.exs` with your keybinding configuration
4. Run `just` to generate and lint `karabinex.json`
5. Run `just replace-config` to copy to Karabiner's complex modifications directory
6. Enable the rules in Karabiner-Elements preferences

## How It Works

Karabinex uses nested keymaps to create multi-key sequences, similar to Emacs prefix keys. When you press a key combination that starts a keymap:

1. Press the initial combination (e.g., `Meh-x`)
2. Release all keys (optional for modifiers if they are used in next key in the sequence)
3. Press the next key in the sequence (e.g., `e`)
4. The bound action executes

Sequences can be arbitrarily deep. For example, `Meh-x r g` means:
1. Press `Meh-x` (Option + Control + Shift + x), release
2. Press `r`, release
3. Press `g` — action executes

If you press an unbound key mid-sequence, the keymap deactivates and nothing happens.

## Configuration

The `rules.exs` file contains a tuple with a description and a map of keybindings:

```elixir
{
  "My keybindings",
  %{
    "Meh-x": %{
      e: {:app, "Emacs"},
      c: {:app, "Brave Browser"},
      s: {:app, "Slack"},
      t: {:app, "Terminal"}
    }
  }
}
```

### Modifier Aliases

| Alias        | Modifier                                   |
|--------------|-------------------------------------------|
| `M-` or `⌥-` | Option                                     |
| `C-` or `^-` | Control                                    |
| `S-`         | Shift                                      |
| `⌘-`         | Command                                    |
| `Meh-`       | Option + Control + Shift                   |
| `H-` or `✦-` | Hyper (Option + Control + Shift + Command) |

### Command Types

| Command                        | Description                         |
|--------------------------------|-------------------------------------|
| `{:app, "App Name"}`           | Launch or focus an application      |
| `{:sh, "command"}`             | Execute a shell command             |
| `{:quit, "App Name"}`          | Gracefully quit an application      |
| `{:kill, "App Name"}`          | Force kill an application (SIGKILL) |
| `{:raycast, "extension/path"}` | Trigger a Raycast extension         |

### Compound Key Bindings

For convenience, you can specify multi-key sequences as a single space-separated key:

```elixir
%{
  "C-c C-x": %{
    e: {:app, "Emacs"},
    c: {:app, "Brave Browser"}
  }
}
```

This is equivalent to:

```elixir
%{
  "C-c": %{
    "C-x": %{
      e: {:app, "Emacs"},
      c: {:app, "Brave Browser"}
    }
  }
}
```

This works with any number of keys: `"C-c C-x C-e"` expands to three levels of nesting.

### Examples

Basic app launching under `Meh-x`:

```elixir
{
  "App launcher",
  %{
    "Meh-x": %{
      e: {:app, "Emacs"},
      c: {:app, "Brave Browser"},
      s: {:app, "Slack"},
      t: {:app, "Terminal"}
    }
  }
}
```

- `Meh-x e` — launch Emacs
- `Meh-x c` — launch Brave Browser

App killing under `Meh-k` (use same letters as launching):

```elixir
{
  "App killer",
  %{
    "Meh-k": %{
      s: {:quit, "Slack"},
      "Meh-s": {:kill, "Slack"},
      e: {:quit, "Emacs"},
      "Meh-e": {:kill, "Emacs"}
    }
  }
}
```

- `Meh-k s` — gracefully quit Slack
- `Meh-k Meh-s` — force kill Slack (SIGKILL)

Shell commands:

```elixir
{
  "Shell commands",
  %{
    "Meh-x": %{
      "Meh-e": {:sh, "emacsclient -c -a '' &"},
      m: {:sh, "pgrep mpv && open -a mpv || true"}
    }
  }
}
```

- `Meh-x Meh-e` — open new Emacs frame via emacsclient

Deeply nested Raycast commands:

```elixir
{
  "Raycast",
  %{
    "Meh-x": %{
      r: %{
        g: {:raycast, "extensions/josephschmitt/gif-search/search"},
        e: {:raycast, "extensions/raycast/emoji-symbols/search-emoji-symbols"},
        t: {:raycast, "extensions/gebeto/translate/translate"},
        b: {:raycast, "extensions/nhojb/brew/search"},
        n: {:raycast, "extensions/raycast/github/notifications"}
      }
    }
  }
}
```

- `Meh-x r g` — search GIFs
- `Meh-x r e` — search emoji
- `Meh-x r t` — translate text

All combined in a single config:

```elixir
{
  "My keybindings",
  %{
    "Meh-x": %{
      e: {:app, "Emacs"},
      "Meh-e": {:sh, "emacsclient -c -a '' &"},
      s: {:app, "Slack"},
      r: %{
        g: {:raycast, "extensions/josephschmitt/gif-search/search"},
        e: {:raycast, "extensions/raycast/emoji-symbols/search-emoji-symbols"}
      }
    },
    "Meh-k": %{
      s: {:quit, "Slack"},
      "Meh-s": {:kill, "Slack"},
      e: {:quit, "Emacs"},
      "Meh-e": {:kill, "Emacs"}
    }
  }
}
```

## Just Commands

| Command               | Description                                     |
|-----------------------|-------------------------------------------------|
| `just`                | Generate config and lint with karabiner_cli     |
| `just replace-config` | Generate and copy to Karabiner config directory |
| `just build`          | Compile with warnings as errors                 |
| `just test`           | Run tests                                       |
| `just typecheck`      | Run dialyzer                                    |
| `just ci`             | Run all checks (build, format, test, typecheck) |
