# Karabinex

A tool for generating [Karabiner-Elements](https://karabiner-elements.pqrs.org/) complex modifications configuration.

Try it in browser: https://vderyagin.github.io/karabinex

## Usage

1. Have [Node.js](https://nodejs.org/) and [Karabiner-Elements](https://karabiner-elements.pqrs.org/) installed.
2. Download the latest release:

   ```sh
   curl -L https://github.com/vderyagin/karabinex/releases/latest/download/karabinex.tar.gz | tar -xz
   ```

3. Move `karabinex` somewhere on your `PATH`, such as `/usr/local/bin` or `~/.local/bin`
4. Create a JSON file with your keybinding configuration
5. Run `karabinex --generate-config ./bindings.json` to generate and lint `karabinex.json`
6. Run `karabinex --replace-config ./bindings.json` to lint and install the generated configuration
7. Enable the rules in Karabiner-Elements preferences
8. Subsequent changes will be applied immediately after running `karabinex --replace-config ./bindings.json`

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

Pass your keybinding file path after the command:

```sh
karabinex --generate-config ./bindings.json
karabinex --generate-config ./bindings.json ./custom-output.json
karabinex --replace-config ./bindings.json
```

`--generate-config` writes to `karabinex.json` in the current directory unless an output path is provided. `--replace-config` installs the generated configuration without writing `karabinex.json` in the current directory.

To lint an already generated config:

```sh
karabinex --lint-config ./path/to/karabinex.json
```

## Development

For local development, install [Bun](https://bun.sh/docs/installation), clone the repository, and run:

```sh
bun install
bun test
bun run build-cli
```

For example, a keybinding file can contain a map like this:

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

### Modifier and Key Aliases

| Syntax       | Meaning                                                      |
|--------------|--------------------------------------------------------------|
| `M-` or `⌥-` | Option                                                       |
| `C-` or `^-` | Control                                                      |
| `S-`         | Shift                                                        |
| `⌘-`         | Command                                                      |
| `Meh-`       | Option + Control + Shift                                     |
| `H-` or `✦-` | Hyper (Option + Control + Shift + Command)                   |
| `A`-`Z`      | Shorthand for `S-a`-`S-z`; invalid with `S-`, `Meh-`, or `H-` |

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
