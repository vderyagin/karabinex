import { describe, expect, test } from "bun:test";
import { preprocess } from "../../src/config";
import { parseJsonConfig } from "../../src/jsonConfig";

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
});
