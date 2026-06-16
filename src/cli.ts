#!/usr/bin/env node
import { copyFileSync, mkdirSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { lintComplexModifications } from "./karabinerCli";
import { updateKarabinerConfig } from "./karabinerConfig";
import { resolvePathArg } from "./pathArg";
import { writeConfig } from "./writeConfig";

type Command = "generate-config" | "lint-config" | "replace-config";

type CliArgs =
  | {
      kind: "help";
    }
  | {
      kind: "run";
      command: Command;
      path?: string;
    };

const usage = `Usage:
  karabinex --generate-config [rules.json]
  karabinex --lint-config [karabinex.json]
  karabinex --replace-config [rules.json]`;

function parseArgs(args: string[]): CliArgs {
  let command: Command | undefined;
  let path: string | undefined;

  for (const arg of args) {
    if (arg === "--help" || arg === "-h") {
      return { kind: "help" };
    }

    if (arg.startsWith("--")) {
      const parsed = parseCommandArg(arg);
      if (command !== undefined) {
        throw new Error("Expected exactly one command option");
      }
      command = parsed.command;
      if (parsed.path !== undefined) {
        path = parsed.path;
      }
      continue;
    }

    if (path !== undefined) {
      throw new Error("Expected at most one path argument");
    }
    path = arg;
  }

  if (command === undefined) {
    throw new Error(`Missing command option\n\n${usage}`);
  }

  return { kind: "run", command, path };
}

function parseCommandArg(arg: string): { command: Command; path?: string } {
  const separator = arg.indexOf("=");
  const flag = separator === -1 ? arg : arg.slice(0, separator);
  const path = separator === -1 ? undefined : arg.slice(separator + 1);

  switch (flag) {
    case "--generate-config":
      return { command: "generate-config", path };
    case "--lint-config":
      return { command: "lint-config", path };
    case "--replace-config":
      return { command: "replace-config", path };
    default:
      throw new Error(`Unknown option: ${flag}`);
  }
}

function run(args: CliArgs): void {
  if (args.kind === "help") {
    console.log(usage);
    return;
  }

  const projectRoot = process.cwd();

  switch (args.command) {
    case "generate-config":
      generateConfig(projectRoot, args.path);
      return;
    case "lint-config":
      lintConfig(projectRoot, args.path);
      return;
    case "replace-config":
      replaceConfig(projectRoot, args.path);
      return;
  }
}

function generateConfig(
  projectRoot: string,
  rulesPathArg: string | undefined,
): void {
  const rulesPath = resolvePathArg(
    pathArgList(rulesPathArg),
    projectRoot,
    "rules.json",
  );
  const outputPath = join(projectRoot, "karabinex.json");

  writeConfig({ rulesPath, outputPath });
  lintComplexModifications(outputPath);
}

function lintConfig(
  projectRoot: string,
  configPathArg: string | undefined,
): void {
  const configPath = resolvePathArg(
    pathArgList(configPathArg),
    projectRoot,
    "karabinex.json",
  );

  lintComplexModifications(configPath);
}

function replaceConfig(
  projectRoot: string,
  rulesPathArg: string | undefined,
): void {
  const rulesPath = resolvePathArg(
    pathArgList(rulesPathArg),
    projectRoot,
    "rules.json",
  );
  const outputPath = join(projectRoot, "karabinex.json");
  const assetPath = join(
    homedir(),
    ".config/karabiner/assets/complex_modifications/karabinex.json",
  );

  writeConfig({ rulesPath, outputPath });
  lintComplexModifications(outputPath);
  mkdirSync(dirname(assetPath), { recursive: true });
  copyFileSync(outputPath, assetPath);
  updateKarabinerConfig(outputPath);
}

function pathArgList(path: string | undefined): string[] {
  return path === undefined ? [] : [path];
}

try {
  run(parseArgs(process.argv.slice(2)));
} catch (error) {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
}
