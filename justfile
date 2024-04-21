default: generate-config

generate-config:
    mix eval "Karabinex.write_config()"

build:
    mix compile

typecheck:
    mix dialyzer

format:
    mix format

repl:
    iex -S mix

key_codes_url := "https://github.com/pqrs-org/Karabiner-Elements/raw/main/src/apps/SettingsWindow/Resources/simple_modifications.json"

fetch-key-codes:
    wget \
      --directory-prefix=./priv/ \
      {{key_codes_url}}
