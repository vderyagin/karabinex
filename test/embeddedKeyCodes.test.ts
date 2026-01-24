import { describe, expect, test } from "bun:test";
import { embeddedKeyCodes } from "../src/web/embeddedKeyCodes";

describe("embeddedKeyCodes", () => {
  test("includes basic key codes", () => {
    expect(embeddedKeyCodes.regular.has("a")).toBe(true);
  });
});
