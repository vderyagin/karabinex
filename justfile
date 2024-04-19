default: build

build:
    mix compile

typecheck:
    mix dialyzer

key_codes_url := "https://github.com/pqrs-org/Karabiner-Elements/raw/main/src/apps/SettingsWindow/Resources/simple_modifications.json"

fetch-key-codes:
    wget --directory-prefix=./priv/  {{key_codes_url}}
