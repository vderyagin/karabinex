import { readFileSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

export type JsonMap = Record<string, unknown>;
export type Rule = JsonMap;

const defaultKarabinerConfigPath = join(
  homedir(),
  ".config/karabiner/karabiner.json",
);

export function updateKarabinerConfig(
  karabinexRulesPath: string,
  configPath = defaultKarabinerConfigPath,
): void {
  const rules = readRules(karabinexRulesPath);
  const config = readJson(configPath);
  const { updated, changed } = replaceRulesInConfig(config, rules);

  if (!changed) {
    return;
  }

  writeJson(configPath, updated);
}

function readRules(path: string): Rule[] {
  const data = readJson(path);
  const rules = data.rules;

  if (Array.isArray(rules) && rules.length > 0) {
    if (!rules.every(isJsonMap)) {
      throw new Error("karabinex.json rules must be objects");
    }
    return rules;
  }

  if (Array.isArray(rules) && rules.length === 0) {
    throw new Error("karabinex.json has no rules");
  }

  throw new Error("karabinex.json missing rules");
}

function readJson(path: string): JsonMap {
  const data: unknown = JSON.parse(readFileSync(path, "utf8"));
  if (!isJsonMap(data)) {
    throw new Error(`Expected JSON object in ${path}`);
  }
  return data;
}

function writeJson(path: string, data: JsonMap): void {
  writeFileSync(path, `${JSON.stringify(data, null, 2)}\n`);
}

function replaceRulesInConfig(
  config: JsonMap,
  newRules: Rule[],
): { updated: JsonMap; changed: boolean } {
  const profiles = config.profiles;
  if (!Array.isArray(profiles)) {
    throw new Error("Karabiner config missing profiles");
  }

  let changed = false;
  const updatedProfiles = profiles.map((profile) => {
    const { updated, changed: profileChanged } = replaceRulesInProfile(
      profile as JsonMap,
      newRules,
    );
    if (profileChanged) {
      changed = true;
    }
    return updated;
  });

  if (!changed) {
    return { updated: config, changed: false };
  }

  return { updated: { ...config, profiles: updatedProfiles }, changed: true };
}

function replaceRulesInProfile(
  profile: JsonMap,
  newRules: Rule[],
): { updated: JsonMap; changed: boolean } {
  const complex = profile.complex_modifications;
  if (!isJsonMap(complex)) {
    return { updated: profile, changed: false };
  }

  const rules = complex.rules;
  if (!Array.isArray(rules)) {
    return { updated: profile, changed: false };
  }

  const { updated, changed } = replaceRules(rules as Rule[], newRules);
  if (!changed) {
    return { updated: profile, changed: false };
  }

  return {
    updated: {
      ...profile,
      complex_modifications: {
        ...complex,
        rules: updated,
      },
    },
    changed: true,
  };
}

function replaceRules(
  existingRules: Rule[],
  newRules: Rule[],
): { updated: Rule[]; changed: boolean } {
  const descriptions = new Set(
    newRules
      .map((rule) => rule.description)
      .filter(
        (description): description is string => typeof description === "string",
      ),
  );

  if (descriptions.size === 0) {
    throw new Error("karabinex.json rules missing descriptions");
  }

  const updated: Rule[] = [];
  let inserted = false;

  for (const rule of existingRules) {
    const description = rule.description;
    if (typeof description === "string" && descriptions.has(description)) {
      if (!inserted) {
        updated.push(...newRules);
        inserted = true;
      }
    } else {
      updated.push(rule);
    }
  }

  if (!inserted) {
    return { updated: existingRules, changed: false };
  }

  return { updated, changed: true };
}

function isJsonMap(value: unknown): value is JsonMap {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
