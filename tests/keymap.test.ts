import { describe, expect, test } from "bun:test";
import { Chord } from "../../src/chord";
import { Command } from "../../src/command";
import { Keymap } from "../../src/keymap";

describe("keymap", () => {
  test("adds hook", () => {
    const chord = Chord.empty();
    const keymap = new Keymap(chord, []);
    const hook = new Command(chord, "sh", "echo hi", false);
    keymap.addHook(hook);
    expect(keymap.hook).toBe(hook);
  });
});
