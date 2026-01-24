import { describe, expect, test } from "bun:test";
import { Chord } from "../src/chord";
import { Command } from "../src/command";

describe("command", () => {
  test("stores fields", () => {
    const chord = Chord.empty();
    const cmd = new Command(chord, "app", "Safari", true);
    expect(cmd.kind).toBe("app");
    expect(cmd.arg).toBe("Safari");
    expect(cmd.repeat).toBe(true);
  });
});
