default: lint format-check typecheck test

export PATH := "/Library/Application Support/org.pqrs/Karabiner-Elements/bin:" + env_var("PATH")

generate-config rules_path='rules.json':
    bun run scripts/generate-config.ts {{rules_path}}

lint-config config_path='karabinex.json':
    bun run scripts/lint-config.ts {{config_path}}

replace-config rules_path='rules.json':
    bun run scripts/replace-config.ts {{rules_path}}

typecheck:
    bun run typecheck

lint:
    bun run lint

lint-fix:
    bun run lint-fix

format:
    bun run format

format-check:
    bun run format-check

test:
    bun test

build-web:
    bun run build-web

key_codes_url := "https://github.com/pqrs-org/Karabiner-Elements/raw/main/src/apps/SettingsWindow/Resources/simple_modifications.json"

fetch-key-codes:
    rm -f ./data/simple_modifications.json
    wget \
      --directory-prefix=./data/ \
      {{key_codes_url}}
