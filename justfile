default: generate-config

generate-config:
    mix eval "Application.ensure_all_started(:karabinex); Karabinex.write_config()"

build:
    mix compile

typecheck:
    mix dialyzer

key_codes_url := "https://github.com/pqrs-org/Karabiner-Elements/raw/main/src/apps/SettingsWindow/Resources/simple_modifications.json"

fetch-key-codes:
    wget \
      --directory-prefix=./priv/ \
      {{key_codes_url}}

repl:
    iex -S mix
