import { describe, expect, test } from "bun:test";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { parseKeyCodes } from "../src/keyCodes";
import { loadKeyCodesFromFile } from "../src/keyCodesFile";

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

  test("loadKeyCodesFromFile reads JSON", () => {
    const dir = mkdtempSync(join(tmpdir(), "karabinex-"));
    const path = join(dir, "keys.json");
    writeFileSync(path, JSON.stringify(sampleData));

    const codes = loadKeyCodesFromFile(path);
    expect(codes.regular.has("a")).toBe(true);

    const raw = readFileSync(path, "utf8");
    expect(raw.length).toBeGreaterThan(0);

    rmSync(dir, { recursive: true, force: true });
  });
});
