import { describe, expect, test } from "bun:test";
import { parseJsonConfig, parseJsonValue } from "../src/jsonConfig";

describe("jsonConfig", () => {
  test("parses command bindings", () => {
    const defs = parseJsonConfig(JSON.stringify({ "C-a": { app: "Safari" } }));
    const entry = defs.entries.get("C-a");
    if (!entry || "entries" in entry) {
      throw new Error("expected command");
    }
    expect(entry.kind).toBe("app");
    expect(entry.arg).toBe("Safari");
  });

  test("parses nested keymaps", () => {
    const defs = parseJsonConfig(
      JSON.stringify({ "C-a": { b: { sh: "echo hi" } } }),
    );
    const entry = defs.entries.get("C-a");
    if (!entry || !("entries" in entry)) {
      throw new Error("expected keymap");
    }
    expect(entry.entries.has("b")).toBe(true);
  });

  test("rejects multiple command keys", () => {
    expect(() =>
      parseJsonConfig(JSON.stringify({ a: { app: "X", sh: "y" } })),
    ).toThrow();
  });

  test("rejects invalid repeat", () => {
    expect(() =>
      parseJsonConfig(JSON.stringify({ a: { sh: "x", repeat: "nope" } })),
    ).toThrow();
  });

  test("rejects reserved keys", () => {
    expect(() =>
      parseJsonConfig(JSON.stringify({ app: { sh: "x" } })),
    ).toThrow();
  });

  test("parseJsonValue accepts object", () => {
    const defs = parseJsonValue({ a: { sh: "x" } });
    expect(defs.entries.has("a")).toBe(true);
  });
});
