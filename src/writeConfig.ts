import { readFileSync, writeFileSync } from "node:fs";
import { embeddedKeyCodes } from "./embeddedKeyCodes";
import { parseJsonConfig } from "./jsonConfig";
import { toManipulators } from "./transform";

export type WriteConfigOptions = {
  rulesPath: string;
  outputPath: string;
  title?: string;
  description?: string;
};

export function writeConfig(options: WriteConfigOptions): void {
  const { rulesPath, outputPath } = options;
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

  writeFileSync(outputPath, `${JSON.stringify(config, null, 2)}\n`);
}
