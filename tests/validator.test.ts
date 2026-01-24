import { describe, expect, test } from "bun:test";
import { KeymapDef } from "../src/jsonConfig";
import { validate } from "../src/validator";
import { makeKeyCodes } from "./testUtils";

describe("validator", () => {
  test("requires modifiers on top-level", () => {
    const defs = new KeymapDef(
      new Map([["a", { kind: "sh", arg: "echo hi" }]]),
    );
    expect(() => validate(defs, makeKeyCodes())).toThrow();
  });

  test("rejects repeat at top level", () => {
    const defs = new KeymapDef(
      new Map([["C-a", { kind: "sh", arg: "echo hi", repeat: "key" }]]),
    );
    expect(() => validate(defs, makeKeyCodes())).toThrow();
  });

  test("rejects duplicate keys", () => {
    const defs = new KeymapDef(
      new Map([
        ["C-a", { kind: "sh", arg: "one" }],
        ["^-a", { kind: "sh", arg: "two" }],
      ]),
    );
    expect(() => validate(defs, makeKeyCodes())).toThrow();
  });

  test("rejects hook at top level", () => {
    const defs = new KeymapDef(new Map([["C-a", { kind: "sh", arg: "x" }]]), {
      kind: "sh",
      arg: "y",
    });
    expect(() => validate(defs, makeKeyCodes())).toThrow();
  });
});
