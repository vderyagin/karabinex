import { describe, expect, test } from "bun:test";
import { preprocess } from "../src/config";
import { parseJsonConfig } from "../src/jsonConfig";

function asKeymap(value: unknown) {
  if (!value || typeof value !== "object" || !("entries" in value)) {
    throw new Error("expected keymap");
  }
  return value as { entries: Map<string, unknown>; hook?: unknown };
}

describe("config", () => {
  test("expands compound keys", () => {
    const defs = parseJsonConfig(
      JSON.stringify({ "C-a C-b": { sh: "echo hi" } }),
    );
    const processed = preprocess(defs);
    const entry = processed.entries.get("C-a");
    const keymap = asKeymap(entry);
    expect(keymap.entries.has("C-b")).toBe(true);
  });

  test("repeat key creates hook keymap", () => {
    const defs = parseJsonConfig(
      JSON.stringify({ "C-a": { sh: "echo hi", repeat: "key" } }),
    );
    const processed = preprocess(defs);
    const entry = processed.entries.get("C-a");
    const keymap = asKeymap(entry);
    expect(keymap.hook).toEqual({ kind: "sh", arg: "echo hi" });
    const child = keymap.entries.get("C-a");
    if (!child || (child as { repeat?: string }).repeat !== "keymap") {
      throw new Error("expected keymap repeat child");
    }
  });

  test("normalizes uppercase letters before parsing", () => {
    const defs = parseJsonConfig(
      JSON.stringify({
        "C-C X": { sh: "echo hi" },
      }),
    );
    const processed = preprocess(defs);
    const entry = processed.entries.get("C-S-c");
    const keymap = asKeymap(entry);
    expect(keymap.entries.has("S-x")).toBe(true);
  });

  test("rejects duplicate keys created by normalization", () => {
    const defs = parseJsonConfig(
      JSON.stringify({
        "C-C": { sh: "echo one" },
        "C-S-c": { sh: "echo two" },
      }),
    );
    expect(() => preprocess(defs)).toThrow(
      "Key normalization creates duplicate keys: C-S-c",
    );
  });

  test("rejects uppercase shorthand when shift is already implied", () => {
    const defs = parseJsonConfig(
      JSON.stringify({
        "Meh-A": { sh: "echo hi" },
      }),
    );
    expect(() => preprocess(defs)).toThrow(
      "Uppercase key cannot be used when shift is already present: Meh-A",
    );
  });
});
