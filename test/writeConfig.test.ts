import { describe, expect, test } from "bun:test";
import {
  existsSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { buildConfig, writeConfig } from "../src/writeConfig";

describe("writeConfig", () => {
  test("builds config json without writing a file", () => {
    const dir = mkdtempSync(join(tmpdir(), "karabinex-"));
    const rulesPath = join(dir, "rules.json");
    const outputPath = join(dir, "karabinex.json");

    writeFileSync(rulesPath, JSON.stringify({ "C-a": { sh: "echo hi" } }));

    const result = JSON.parse(buildConfig({ rulesPath })) as {
      rules: unknown[];
    };

    expect(Array.isArray(result.rules)).toBe(true);
    expect(result.rules.length).toBe(1);
    expect(existsSync(outputPath)).toBe(false);

    rmSync(dir, { recursive: true, force: true });
  });

  test("writes karabinex.json", () => {
    const dir = mkdtempSync(join(tmpdir(), "karabinex-"));
    const rulesPath = join(dir, "rules.json");
    const outputPath = join(dir, "karabinex.json");

    writeFileSync(rulesPath, JSON.stringify({ "C-a": { sh: "echo hi" } }));

    writeConfig({ rulesPath, outputPath });

    const result = JSON.parse(readFileSync(outputPath, "utf8")) as {
      rules: unknown[];
    };
    expect(Array.isArray(result.rules)).toBe(true);
    expect(result.rules.length).toBe(1);

    rmSync(dir, { recursive: true, force: true });
  });
});
