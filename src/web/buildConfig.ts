import { parseJsonConfig } from "../jsonConfig";
import type { KeyCodes } from "../keyCodes";
import { toManipulators } from "../transform";
import { embeddedKeyCodes } from "./embeddedKeyCodes";

export type WebConfig = {
  title: string;
  rules: {
    description: string;
    manipulators: unknown[];
  }[];
};

export type BuildConfigOptions = {
  title?: string;
  description?: string;
  keyCodes?: KeyCodes;
};

export function buildConfig(
  rulesJson: string,
  options: BuildConfigOptions = {},
): WebConfig {
  const title = options.title ?? "karabinex bindings";
  const description = options.description ?? "karabinex bindings";
  const keyCodes = options.keyCodes ?? embeddedKeyCodes;

  const defs = parseJsonConfig(rulesJson);
  const manipulators = toManipulators(defs, keyCodes);

  return {
    title,
    rules: [
      {
        description,
        manipulators,
      },
    ],
  };
}

export function buildConfigJson(
  rulesJson: string,
  options: BuildConfigOptions = {},
): string {
  const config = buildConfig(rulesJson, options);
  return `${JSON.stringify(config, null, 2)}\n`;
}
