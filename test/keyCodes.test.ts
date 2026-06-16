import { describe, expect, test } from "bun:test";
import { parseKeyCodes } from "../src/keyCodes";

const sampleData = [
  { data: [{ key_code: "a" }] },
  { data: [{ consumer_key_code: "volume_up" }] },
  { data: [{ pointing_button: "button1" }] },
  { data: [{ key_code: "b" }] },
  { data: [] },
];

describe("keyCodes", () => {
  test("parseKeyCodes collects key types", () => {
    const codes = parseKeyCodes(sampleData);
    expect(codes.regular.has("a")).toBe(true);
    expect(codes.regular.has("b")).toBe(true);
    expect(codes.consumer.has("volume_up")).toBe(true);
    expect(codes.pointer.has("button1")).toBe(true);
  });
});
