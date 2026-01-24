import { describe, expect, test } from "bun:test";
import { parseKeyCodes } from "../src/keyCodes";
import { buildConfig, buildConfigJson } from "../src/web/buildConfig";

const keyCodes = parseKeyCodes([{ data: [{ key_code: "a" }] }]);
const rulesJson = JSON.stringify({ a: { app: "Notes" } });

describe("buildConfig", () => {
  test("builds config with custom metadata", () => {
    const config = buildConfig(rulesJson, {
      keyCodes,
      title: "Custom Title",
      description: "Custom Description",
    });

    expect(config.title).toBe("Custom Title");
    expect(config.rules[0]?.description).toBe("Custom Description");
    expect(Array.isArray(config.rules[0]?.manipulators)).toBe(true);
  });

  test("buildConfigJson formats output", () => {
    const json = buildConfigJson(rulesJson, { keyCodes });
    expect(json.endsWith("\n")).toBe(true);

    const parsed = JSON.parse(json) as { rules?: Array<{ manipulators?: unknown[] }> };
    expect(parsed.rules?.[0]?.manipulators?.length).toBeGreaterThan(0);
  });
});
