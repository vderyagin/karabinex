import {
  type CommandDef,
  type CommandKind,
  commandKinds,
  isCommandKind,
} from "./command";
import type { Binding } from "./jsonConfig";
import { KeymapDef } from "./jsonConfig";
import { Key } from "./key";
import type { KeyCodes } from "./keyCodes";

export function validate(defs: KeymapDef, keyCodes: KeyCodes): void {
  validateDefinitions(defs, 0, keyCodes);
}

function validateDefinitions(
  defs: KeymapDef,
  depth: number,
  keyCodes: KeyCodes,
): void {
  validateNotEmpty(defs, depth);
  validateHook(defs, depth);
  validateNoDuplicates(defs, keyCodes);

  for (const [key, value] of defs.entries) {
    validateDefinition(key, value, depth, keyCodes);
  }
}

function validateHook(defs: KeymapDef, depth: number): void {
  if (!defs.hook) {
    return;
  }

  if (depth === 0) {
    throw new Error("__hook__ cannot be used at top level");
  }

  if (defs.hook.repeat !== undefined) {
    throw new Error(
      `Hook cannot have options: ${JSON.stringify({ repeat: defs.hook.repeat })}`,
    );
  }

  validateKind(defs.hook.kind);
  validateArg(defs.hook.arg);
}

function validateNotEmpty(defs: KeymapDef, depth: number): void {
  if (defs.entries.size === 0 && depth === 0) {
    throw new Error("Config cannot be empty");
  }

  if (defs.entries.size === 0 && depth > 0) {
    throw new Error("Empty keymap is not allowed");
  }
}

function validateNoDuplicates(defs: KeymapDef, keyCodes: KeyCodes): void {
  const groups = new Map<string, string[]>();

  for (const [key] of defs.entries) {
    const parsed = Key.parse(key, keyCodes);
    const groupKey = `${parsed.code.type}:${parsed.code.code}:${parsed.modifierSetKey()}`;
    const list = groups.get(groupKey);
    if (list) {
      list.push(key);
    } else {
      groups.set(groupKey, [key]);
    }
  }

  const duplicates = [...groups.values()].filter(
    (entries) => entries.length > 1,
  );
  if (duplicates.length === 0) {
    return;
  }

  const keys = duplicates
    .map((entries) => entries.map((entry) => JSON.stringify(entry)).join(", "))
    .join("; ");
  throw new Error(`Duplicate keys detected: ${keys}`);
}

function validateDefinition(
  key: string,
  value: Binding,
  depth: number,
  keyCodes: KeyCodes,
): void {
  if (value instanceof KeymapDef) {
    validateTopLevelModifiers(key, depth, keyCodes);
    validateKey(key, keyCodes);
    validateDefinitions(value, depth + 1, keyCodes);
    return;
  }

  validateTopLevelModifiers(key, depth, keyCodes);
  validateKey(key, keyCodes);
  validateKind(value.kind);
  validateArg(value.arg);
  validateNoRepeatAtTop(value, depth, key);
}

function validateKey(key: string, keyCodes: KeyCodes): void {
  try {
    Key.parse(key, keyCodes);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    throw new Error(`Invalid key ${JSON.stringify(key)}: ${message}`);
  }
}

function validateKind(kind: CommandKind): void {
  if (!isCommandKind(kind)) {
    throw new Error(
      `Unknown command type: ${JSON.stringify(kind)}. Valid types: ${JSON.stringify(commandKinds)}`,
    );
  }
}

function validateArg(arg: unknown): void {
  if (typeof arg !== "string") {
    throw new Error(
      `Command argument must be a string, got: ${JSON.stringify(arg)}`,
    );
  }
}

function validateNoRepeatAtTop(
  command: CommandDef,
  depth: number,
  key: string,
): void {
  if (depth === 0 && command.repeat !== undefined) {
    throw new Error(
      `repeat: ${JSON.stringify(command.repeat)} cannot be used at top level (key: ${JSON.stringify(key)})`,
    );
  }
}

function validateTopLevelModifiers(
  key: string,
  depth: number,
  keyCodes: KeyCodes,
): void {
  if (depth !== 0) {
    return;
  }

  const parsed = Key.parse(key, keyCodes);
  if (!parsed.hasModifiers()) {
    throw new Error(
      `Top-level key must include modifiers: ${JSON.stringify(key)}`,
    );
  }
}
