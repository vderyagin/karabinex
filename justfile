default: lint format-check typecheck test

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

build-cli:
    bun run build-cli

key_codes_url := "https://github.com/pqrs-org/Karabiner-Elements/raw/main/src/apps/SettingsWindow/Resources/simple_modifications.json"

fetch-key-codes:
    rm -f ./data/simple_modifications.json
    wget \
      --directory-prefix=./data/ \
      {{key_codes_url}}
