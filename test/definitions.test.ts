import { describe, expect, test } from "bun:test";
import { Command } from "../src/command";
import { preprocess } from "../src/config";
import { parseDefinitions } from "../src/definitions";
import { parseJsonConfig } from "../src/jsonConfig";
import { Keymap } from "../src/keymap";
import { makeKeyCodes } from "./testUtils";

describe("definitions", () => {
  test("builds keymap with hook and repeat child", () => {
    const defs = preprocess(
      parseJsonConfig(
        JSON.stringify({ "C-a": { sh: "echo hi", repeat: "key" } }),
      ),
    );
    const items = parseDefinitions(defs, makeKeyCodes());
    expect(items.length).toBe(1);
    const keymap = items[0] as Keymap;
    expect(keymap instanceof Keymap).toBe(true);
    expect(keymap.hook).toBeDefined();

    const child = keymap.children[0];
    expect(child instanceof Command).toBe(true);
    if (child instanceof Command) {
      expect(child.repeat).toBe(true);
    }
  });
});
