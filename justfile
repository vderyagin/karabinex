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
    mix deps.get
    mix compile --warnings-as-errors

outdated-deps:
    mix hex.outdated

update-deps:
    mix deps.update --all

typecheck:
    mix dialyzer

format:
    mix format

format-check:
    mix format --check-formatted

repl:
    iex -S mix

clean:
    mix clean
    rm -rf ./deps/ ./_build/

test:
    mix test

# run approximately the same stuff that is run in CI
ci: build format-check test typecheck

key_codes_url := "https://github.com/pqrs-org/Karabiner-Elements/raw/main/src/apps/SettingsWindow/Resources/simple_modifications.json"

fetch-key-codes:
    rm -f ./priv/simple_modifications.json
    wget \
      --directory-prefix=./priv/ \
      {{key_codes_url}}
