default: build

typecheck:
    bun run typecheck

lint:
    bun run lint

fix-lint:
    bun run fix-lint

format:
    bun run format

check-format:
    bun run check-format

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

check: check-format typecheck lint test build

build: build-cli build-web
