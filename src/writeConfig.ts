import { readFileSync, writeFileSync } from "node:fs";
import { embeddedKeyCodes } from "./embeddedKeyCodes";
import { parseJsonConfig } from "./jsonConfig";
import { toManipulators } from "./transform";

export type BuildConfigOptions = {
  rulesPath: string;
  title?: string;
  description?: string;
};

export type WriteConfigOptions = BuildConfigOptions & {
  outputPath: string;
};

export function buildConfig(options: BuildConfigOptions): string {
  const { rulesPath } = options;
  const title = options.title ?? "karabinex bindings";
  const description = options.description ?? "karabinex bindings";

  const rulesJson = readFileSync(rulesPath, "utf8");
  const defs = parseJsonConfig(rulesJson);
  const manipulators = toManipulators(defs, embeddedKeyCodes);

  const config = {
    title,
    rules: [
      {
        description,
        manipulators,
      },
    ],
  };

  return `${JSON.stringify(config, null, 2)}\n`;
}

export function writeConfig(options: WriteConfigOptions): void {
  const { outputPath } = options;

  writeFileSync(outputPath, buildConfig(options));
}
