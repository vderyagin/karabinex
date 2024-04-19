default: build

build:
    mix compile

typecheck:
    mix dialyzer
