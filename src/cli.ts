#!/usr/bin/env node
import { mkdirSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import {
  lintComplexModifications,
  lintComplexModificationsJson,
} from "./karabinerCli";
import { updateKarabinerConfigJson } from "./karabinerConfig";
import { resolvePathArg } from "./pathArg";
import { buildConfig, writeConfig } from "./writeConfig";

type Command = "generate-config" | "lint-config" | "replace-config";

type RunArgs = {
  command: Command;
  paths: string[];
};

type CliArgs =
  | {
      kind: "help";
    }
  | ({ kind: "run" } & RunArgs);

const usage = `Usage:
  karabinex --generate-config <bindings.json> [output.json]
  karabinex --lint-config <karabinex.json>
  karabinex --replace-config <bindings.json>`;

function parseArgs(args: string[]): CliArgs {
  let command: Command | undefined;
  const paths: string[] = [];

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
        paths.push(parsed.path);
      }
      continue;
    }

    paths.push(arg);
  }

  if (command === undefined) {
    throw new Error(`Missing command option\n\n${usage}`);
  }

  return { kind: "run", command, paths };
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
      generateConfig(projectRoot, args.paths);
      return;
    case "lint-config":
      lintConfig(projectRoot, args.paths);
      return;
    case "replace-config":
      replaceConfig(projectRoot, args.paths);
      return;
  }
}

function generateConfig(projectRoot: string, paths: string[]): void {
  assertPathCount(paths, "--generate-config", 1, 2);
  const rulesPath = resolvePathArg([paths[0] ?? ""], projectRoot, "");
  const outputPath = resolvePathArg(
    paths.slice(1),
    projectRoot,
    "karabinex.json",
  );

  writeConfig({ rulesPath, outputPath });
  lintComplexModifications(outputPath);
}

function lintConfig(projectRoot: string, paths: string[]): void {
  assertPathCount(paths, "--lint-config", 1, 1);
  const configPath = resolvePathArg([paths[0] ?? ""], projectRoot, "");

  lintComplexModifications(configPath);
}

function replaceConfig(projectRoot: string, paths: string[]): void {
  assertPathCount(paths, "--replace-config", 1, 1);
  const rulesPath = resolvePathArg([paths[0] ?? ""], projectRoot, "");
  const assetPath = join(
    homedir(),
    ".config/karabiner/assets/complex_modifications/karabinex.json",
  );
  const configJson = buildConfig({ rulesPath });

  lintComplexModificationsJson(configJson);
  mkdirSync(dirname(assetPath), { recursive: true });
  writeFileSync(assetPath, configJson);
  updateKarabinerConfigJson(configJson);
}

function assertPathCount(
  paths: string[],
  command: string,
  min: number,
  max: number,
): void {
  if (paths.length < min) {
    throw new Error(`Missing file path for ${command}\n\n${usage}`);
  }

  if (paths.length > max) {
    throw new Error(`Too many file paths for ${command}\n\n${usage}`);
  }
}

try {
  run(parseArgs(process.argv.slice(2)));
} catch (error) {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
}
