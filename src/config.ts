import type { CommandDef } from "./command";
import type { Binding, KeymapDef } from "./jsonConfig";
import { KeymapDef as KeymapDefClass } from "./jsonConfig";

export function preprocess(defs: KeymapDef): KeymapDef {
  const expanded = [...defs.entries].map(expandCompoundKey);
  validateNoConflictingExpansions(expanded);
  const processed = expanded.map(([key, value]) =>
    preprocessDefinition(key, value),
  );
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

function validateNoConflictingExpansions(
  expanded: Array<[string, Binding]>,
): void {
  const counts = new Map<string, number>();
  for (const [key] of expanded) {
    const keyStr = String(key);
    counts.set(keyStr, (counts.get(keyStr) ?? 0) + 1);
  }

  const duplicates = [...counts.entries()]
    .filter(([, count]) => count > 1)
    .map(([key]) => key);
  if (duplicates.length > 0) {
    throw new Error(
      `Compound key expansion creates duplicate keys: ${duplicates.join(", ")}`,
    );
  }
}

function preprocessDefinition(key: string, value: Binding): [string, Binding] {
  if (value instanceof KeymapDefClass) {
    return [key, preprocess(value)];
  }

  if (value.repeat === "key") {
    const hook: CommandDef = { kind: value.kind, arg: value.arg };
    const child: CommandDef = {
      kind: value.kind,
      arg: value.arg,
      repeat: "keymap",
    };
    const entries = new Map<string, Binding>([[key, child]]);
    return [key, new KeymapDefClass(entries, hook)];
  }

  return [key, value];
}
