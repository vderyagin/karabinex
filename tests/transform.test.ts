import { describe, expect, test } from "bun:test";
import { parseJsonConfig } from "../../src/jsonConfig";
import { toManipulators } from "../../src/transform";
import { makeKeyCodes } from "../testUtils";

describe("transform", () => {
  test("generates manipulators", () => {
    const defs = parseJsonConfig(
      JSON.stringify({ "C-a": { b: { sh: "echo hi" } } }),
    );
    const manipulators = toManipulators(defs, makeKeyCodes());
    expect(manipulators.length).toBeGreaterThan(0);

    const hasEnable = manipulators.some(
      (m) =>
        Array.isArray(m.to) &&
        m.to.some(
          (clause) => (clause as { set_variable?: unknown }).set_variable,
        ),
    );
    expect(hasEnable).toBe(true);
  });
});
