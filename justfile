default: lint format typecheck test

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

lint:
    bun run lint

lint-fix:
    bun run lint-fix

format-fix:
    bun run format

format:
    bun run format-check

test:
    bun test

key_codes_url := "https://github.com/pqrs-org/Karabiner-Elements/raw/main/src/apps/SettingsWindow/Resources/simple_modifications.json"

fetch-key-codes:
    rm -f ./data/simple_modifications.json
    wget \
      --directory-prefix=./data/ \
      {{key_codes_url}}
