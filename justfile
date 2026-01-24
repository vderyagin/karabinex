default: format-check test typecheck

export PATH := "/Library/Application Support/org.pqrs/Karabiner-Elements/bin:" + env_var("PATH")

generate-config: && lint-config
    bun run generate-config

lint-config:
    karabiner_cli \
      --lint-complex-modifications \
      karabinex.json

replace-config: generate-config
    bun run replace-config

typecheck:
    bun run typecheck

typecheck:
    bun run typecheck

format:
    bun run format

format-check:
    bun run format-check

test:
    bun test

skey_codes_url := "https://github.com/pqrs-org/Karabiner-Elements/raw/main/src/apps/SettingsWindow/Resources/simple_modifications.json"

fetch-key-codes:
    rm -f ./priv/simple_modifications.json
    wget \
      --directory-prefix=./priv/ \
      {{key_codes_url}}
