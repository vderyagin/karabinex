import { readFileSync, writeFileSync } from "node:fs";
import { parseJsonConfig } from "./jsonConfig";
import { loadKeyCodesFromFile } from "./keyCodesFile";
import { toManipulators } from "./transform";

export type WriteConfigOptions = {
  rulesPath: string;
  outputPath: string;
  keyCodesPath: string;
  title?: string;
  description?: string;
};

export function writeConfig(options: WriteConfigOptions): void {
  const { rulesPath, outputPath, keyCodesPath } = options;
  const title = options.title ?? "karabinex bindings";
  const description = options.description ?? "karabinex bindings";

  const rulesJson = readFileSync(rulesPath, "utf8");
  const keyCodes = loadKeyCodesFromFile(keyCodesPath);
  const defs = parseJsonConfig(rulesJson);
  const manipulators = toManipulators(defs, keyCodes);

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
