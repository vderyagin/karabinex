import { describe, expect, test } from "bun:test";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { writeConfig } from "../src/writeConfig";

const keyCodesData = [{ data: [{ key_code: "a" }] }];

describe("writeConfig", () => {
  test("writes karabinex.json", () => {
    const dir = mkdtempSync(join(tmpdir(), "karabinex-"));
    const rulesPath = join(dir, "rules.json");
    const outputPath = join(dir, "karabinex.json");
    const keyCodesPath = join(dir, "keys.json");

    writeFileSync(rulesPath, JSON.stringify({ "C-a": { sh: "echo hi" } }));
    writeFileSync(keyCodesPath, JSON.stringify(keyCodesData));

    writeConfig({ rulesPath, outputPath, keyCodesPath });

    const result = JSON.parse(readFileSync(outputPath, "utf8")) as {
      rules: unknown[];
    };
    expect(Array.isArray(result.rules)).toBe(true);
    expect(result.rules.length).toBe(1);

    rmSync(dir, { recursive: true, force: true });
  });
});
