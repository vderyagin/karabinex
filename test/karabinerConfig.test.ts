import { describe, expect, test } from "bun:test";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import {
  updateKarabinerConfig,
  updateKarabinerConfigJson,
} from "../src/karabinerConfig";

function writeJson(path: string, data: unknown): void {
  writeFileSync(path, `${JSON.stringify(data, null, 2)}\n`);
}

describe("karabinerConfig", () => {
  test("replaces rules from json content", () => {
    const dir = mkdtempSync(join(tmpdir(), "karabinex-"));
    const configPath = join(dir, "karabiner.json");
    const karabinexJson = `${JSON.stringify(
      {
        rules: [
          {
            description: "karabinex bindings",
            manipulators: [{ type: "basic" }],
          },
        ],
      },
      null,
      2,
    )}\n`;

    writeJson(configPath, {
      profiles: [
        {
          name: "Default",
          complex_modifications: {
            rules: [
              {
                description: "karabinex bindings",
                manipulators: [{ old: true }],
              },
            ],
          },
        },
      ],
    });

    updateKarabinerConfigJson(karabinexJson, configPath);

    const updated = JSON.parse(readFileSync(configPath, "utf8")) as {
      profiles: Array<{
        complex_modifications: {
          rules: Array<{ description: string; manipulators: unknown[] }>;
        };
      }>;
    };

    const profile = updated.profiles[0];
    if (!profile) {
      throw new Error("Missing profile");
    }

    expect(profile.complex_modifications.rules[0]?.manipulators).toEqual([
      { type: "basic" },
    ]);

    rmSync(dir, { recursive: true, force: true });
  });

  test("replaces rules by description", () => {
    const dir = mkdtempSync(join(tmpdir(), "karabinex-"));
    const karabinexPath = join(dir, "karabinex.json");
    const configPath = join(dir, "karabiner.json");

    writeJson(karabinexPath, {
      rules: [
        {
          description: "karabinex bindings",
          manipulators: [{ type: "basic" }],
        },
      ],
    });

    writeJson(configPath, {
      profiles: [
        {
          name: "Default",
          complex_modifications: {
            rules: [
              {
                description: "karabinex bindings",
                manipulators: [{ old: true }],
              },
              { description: "other", manipulators: [{ keep: true }] },
            ],
          },
        },
      ],
    });

    updateKarabinerConfig(karabinexPath, configPath);

    const updated = JSON.parse(readFileSync(configPath, "utf8")) as {
      profiles: Array<{
        complex_modifications: {
          rules: Array<{ description: string; manipulators: unknown[] }>;
        };
      }>;
    };

    const profile = updated.profiles[0];
    if (!profile) {
      throw new Error("Missing profile");
    }
    const rules = profile.complex_modifications.rules;
    const first = rules.find(
      (rule) => rule.description === "karabinex bindings",
    );
    const other = rules.find((rule) => rule.description === "other");

    expect(first?.manipulators).toEqual([{ type: "basic" }]);
    expect(other?.manipulators).toEqual([{ keep: true }]);

    rmSync(dir, { recursive: true, force: true });
  });
});
