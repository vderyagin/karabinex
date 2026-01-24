# Karabinex

A tool for generating [Karabiner-Elements](https://karabiner-elements.pqrs.org/) complex modifications configuration.

Try it in browser: https://vderyagin.github.io/karabinex

## Usage

1. Clone the repository
2. Edit `rules.json` with your keybinding configuration
3. Run `just generate-config` to generate and lint `karabinex.json`
4. Run `just replace-config` to copy to Karabiner's complex modifications directory
5. Enable the rules in Karabiner-Elements preferences
6. Subsequent changes will be applied immediately after running `just replace-config`

## Development

- `just test` runs the test suite (unit + integration).
- `just typecheck` runs TypeScript typechecking (no emit).
- `just format` and `just format-check` use Biome.

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

The `rules.json` file contains a map of keybindings:

```json
{
  "Meh-x": {
    "e": { "app": "Emacs" },
    "c": { "app": "Brave Browser" },
    "s": { "app": "Slack" },
    "t": { "app": "Terminal" }
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

| Command                                | Description                         |
|----------------------------------------|-------------------------------------|
| `{ "app": "App Name" }`                | Launch or focus an application      |
| `{ "sh": "command" }`                  | Execute a shell command             |
| `{ "quit": "App Name" }`               | Gracefully quit an application      |
| `{ "kill": "App Name" }`               | Force kill an application (SIGKILL) |
| `{ "raycast": "extension/path" }`      | Trigger a Raycast extension         |
| `{ "raycast": "...", "repeat": "key" }`| Repeatable keymap hook (repeat key) |

### Compound Key Bindings

For convenience, you can specify multi-key sequences as a single space-separated key:

```json
{
  "C-c C-x": {
    "e": { "app": "Emacs" },
    "c": { "app": "Brave Browser" }
  }
}
```

This is equivalent to:

```json
{
  "C-c": {
    "C-x": {
      "e": { "app": "Emacs" },
      "c": { "app": "Brave Browser" }
    }
  }
}
```

This works with any number of keys: `"C-c C-x C-e"` expands to three levels of nesting.

### Examples

Basic app launching under `Meh-x`:

```json
{
  "Meh-x": {
    "e": { "app": "Emacs" },
    "c": { "app": "Brave Browser" },
    "s": { "app": "Slack" },
    "t": { "app": "Terminal" }
  }
}
```

- `Meh-x e` — launch Emacs
- `Meh-x c` — launch Brave Browser

App killing under `Meh-k` (use same letters as launching):

```json
{
  "Meh-k": {
    "s": { "quit": "Slack" },
    "Meh-s": { "kill": "Slack" },
    "e": { "quit": "Emacs" },
    "Meh-e": { "kill": "Emacs" }
  }
}
```

- `Meh-k s` — gracefully quit Slack
- `Meh-k Meh-s` — force kill Slack (SIGKILL)

Shell commands:

```json
{
  "Meh-x": {
    "Meh-e": { "sh": "emacsclient -c -a '' &" },
    "m": { "sh": "pgrep mpv && open -a mpv || true" }
  }
}
```

- `Meh-x Meh-e` — open new Emacs frame via emacsclient

Deeply nested Raycast commands:

```json
{
  "Meh-x": {
    "r": {
      "g": { "raycast": "extensions/josephschmitt/gif-search/search" },
      "e": { "raycast": "extensions/raycast/emoji-symbols/search-emoji-symbols" },
      "t": { "raycast": "extensions/gebeto/translate/translate" },
      "b": { "raycast": "extensions/nhojb/brew/search" },
      "n": { "raycast": "extensions/raycast/github/notifications" }
    }
  }
}
```

- `Meh-x r g` — search GIFs
- `Meh-x r e` — search emoji
- `Meh-x r t` — translate text

All combined in a single config:

```json
{
  "Meh-x": {
    "e": { "app": "Emacs" },
    "Meh-e": { "sh": "emacsclient -c -a '' &" },
    "s": { "app": "Slack" },
    "r": {
      "g": { "raycast": "extensions/josephschmitt/gif-search/search" },
      "e": { "raycast": "extensions/raycast/emoji-symbols/search-emoji-symbols" }
    }
  },
  "Meh-k": {
    "s": { "quit": "Slack" },
    "Meh-s": { "kill": "Slack" },
    "e": { "quit": "Emacs" },
    "Meh-e": { "kill": "Emacs" }
  }
}
```
