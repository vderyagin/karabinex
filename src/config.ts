import type { CommandDef } from "./command";
import type { Binding, KeymapDef } from "./jsonConfig";
import { KeymapDef as KeymapDefClass } from "./jsonConfig";

const hyperPrefix = "\u2726-";
const commandPrefix = "\u2318-";
const optionPrefix = "\u2325-";

export function preprocess(defs: KeymapDef): KeymapDef {
  const expanded = [...defs.entries].map(expandCompoundKey);
  validateUniqueKeys(expanded, "Compound key expansion creates duplicate keys");
  const processed = expanded.map(([key, value]) =>
    preprocessDefinition(key, value),
  );
  validateUniqueKeys(processed, "Key normalization creates duplicate keys");
  return new KeymapDefClass(new Map(processed), defs.hook);
}

function expandCompoundKey([key, value]: readonly [string, Binding]): [
  string,
  Binding,
] {
  const keyStr = String(key);
  const parts = keyStr.split(" ", 2);

  if (parts.length === 2) {
    const first = parts[0];
    const rest = parts[1];
    if (first && rest) {
      const nested = new KeymapDefClass(new Map([[rest, value]]));
      return expandCompoundKey([first, nested]);
    }
  }

  return [key, value];
}

function validateUniqueKeys(
  entries: Array<[string, Binding]>,
  message: string,
): void {
  const counts = new Map<string, number>();
  for (const [key] of entries) {
    const keyStr = String(key);
    counts.set(keyStr, (counts.get(keyStr) ?? 0) + 1);
  }

  const duplicates = [...counts.entries()]
    .filter(([, count]) => count > 1)
    .map(([key]) => key);
  if (duplicates.length > 0) {
    throw new Error(`${message}: ${duplicates.join(", ")}`);
  }
}

function preprocessDefinition(key: string, value: Binding): [string, Binding] {
  const normalizedKey = normalizeKeyString(key);

  if (value instanceof KeymapDefClass) {
    return [normalizedKey, preprocess(value)];
  }

  if (value.repeat === "key") {
    const hook: CommandDef = { kind: value.kind, arg: value.arg };
    const child: CommandDef = {
      kind: value.kind,
      arg: value.arg,
      repeat: "keymap",
    };
    const entries = new Map<string, Binding>([[normalizedKey, child]]);
    return [normalizedKey, new KeymapDefClass(entries, hook)];
  }

  return [normalizedKey, value];
}

function normalizeKeyString(key: string): string {
  return key
    .split(" ")
    .map((part) => normalizeKeyPart(part))
    .join(" ");
}

function normalizeKeyPart(key: string): string {
  let rest = key;
  let prefix = "";
  let hasShift = false;

  while (true) {
    if (rest.startsWith("H-")) {
      prefix += "H-";
      hasShift = true;
      rest = rest.slice(2);
      continue;
    }
    if (rest.startsWith(hyperPrefix)) {
      prefix += hyperPrefix;
      hasShift = true;
      rest = rest.slice(hyperPrefix.length);
      continue;
    }
    if (rest.startsWith("Meh-")) {
      prefix += "Meh-";
      hasShift = true;
      rest = rest.slice(4);
      continue;
    }
    if (rest.startsWith(commandPrefix)) {
      prefix += commandPrefix;
      rest = rest.slice(commandPrefix.length);
      continue;
    }
    if (rest.startsWith("M-")) {
      prefix += "M-";
      rest = rest.slice(2);
      continue;
    }
    if (rest.startsWith(optionPrefix)) {
      prefix += optionPrefix;
      rest = rest.slice(optionPrefix.length);
      continue;
    }
    if (rest.startsWith("^-")) {
      prefix += "^-";
      rest = rest.slice(2);
      continue;
    }
    if (rest.startsWith("C-")) {
      prefix += "C-";
      rest = rest.slice(2);
      continue;
    }
    if (rest.startsWith("S-")) {
      prefix += "S-";
      hasShift = true;
      rest = rest.slice(2);
      continue;
    }
    break;
  }

  if (!/^[A-Z]$/.test(rest)) {
    return key;
  }

  if (hasShift) {
    throw new Error(
      `Uppercase key cannot be used when shift is already present: ${key}`,
    );
  }

  return `${prefix}S-${rest.toLowerCase()}`;
}
