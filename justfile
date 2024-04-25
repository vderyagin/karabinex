default: generate-config

export PATH := "/Library/Application Support/org.pqrs/Karabiner-Elements/bin:" + env_var("PATH")

generate-config:
    mix eval "Karabinex.write_config()"
    karabiner_cli \
      --lint-complex-modifications \
      karabinex.json

replace-config: generate-config
    cp -f \
      karabinex.json \
      ~/.config/karabiner/assets/complex_modifications/karabinex.json

build:
    mix compile

typecheck:
    mix dialyzer

format:
    mix format

repl:
    iex -S mix

clean:
    mix clean
    rm -rf ./deps/ ./_build/

key_codes_url := "https://github.com/pqrs-org/Karabiner-Elements/raw/main/src/apps/SettingsWindow/Resources/simple_modifications.json"

fetch-key-codes:
    rm -f ./priv/simple_modifications.json
    wget \
      --directory-prefix=./priv/ \
      {{key_codes_url}}
