import {
  type CommandDef,
  type CommandKind,
  commandKinds,
  isCommandKind,
  isRepeatValue,
  type RepeatValue,
} from "./command";

export type Binding = CommandDef | KeymapDef;

export class KeymapDef {
  readonly entries: ReadonlyMap<string, Binding>;
  readonly hook?: CommandDef;

  constructor(entries: ReadonlyMap<string, Binding>, hook?: CommandDef) {
    this.entries = entries;
    this.hook = hook;
  }
}

const reservedKeyNames = new Set<string>([...commandKinds, "repeat"]);

export function parseJsonConfig(json: string): KeymapDef {
  const data: unknown = JSON.parse(json);
  return parseMap(data);
}

export function parseJsonValue(value: unknown): KeymapDef {
  return parseMap(value);
}

function parseMap(data: unknown): KeymapDef {
  if (!isPlainObject(data)) {
    throw new Error("JSON config must be an object");
  }

  const entries = new Map<string, Binding>();
  if (Object.keys(data).length === 0) {
    return new KeymapDef(entries);
  }

  const keymap = parseKeymap(data, []);
  return new KeymapDef(keymap.entries, keymap.hook);
}

function parseKeymap(map: Record<string, unknown>, path: string[]): KeymapDef {
  if (Object.keys(map).length === 0) {
    throw new Error(`Empty keymap at ${pathLabel(path)}`);
  }

  const entries = new Map<string, Binding>();

  for (const [key, value] of Object.entries(map)) {
    if (reservedKeyNames.has(key)) {
      throw new Error(
        `Reserved key ${JSON.stringify(key)} at ${pathLabel(path)}`,
      );
    }
    entries.set(key, parseBinding(value, [...path, key]));
  }

  return new KeymapDef(entries);
}

function parseBinding(value: unknown, path: string[]): Binding {
  if (!isPlainObject(value)) {
    throw new Error(`Binding must be an object at ${pathLabel(path)}`);
  }

  const keys = Object.keys(value).filter(isCommandKind);

  if (keys.length === 0) {
    return parseKeymap(value, path);
  }

  if (keys.length === 1) {
    const commandKey = keys[0];
    if (!commandKey) {
      throw new Error(`Missing command key at ${pathLabel(path)}`);
    }
    return parseCommand(value, commandKey, path);
  }

  throw new Error(`Multiple command keys at ${pathLabel(path)}`);
}

function parseCommand(
  value: Record<string, unknown>,
  commandKey: CommandKind,
  path: string[],
): CommandDef {
  const arg = value[commandKey];
  if (typeof arg !== "string") {
    throw new Error(
      `Command ${JSON.stringify(commandKey)} argument must be a string at ${pathLabel(path)}`,
    );
  }

  const repeat = parseRepeat(value.repeat, path);

  const extras = Object.keys(value).filter(
    (key) => key !== commandKey && key !== "repeat",
  );
  if (extras.length > 0) {
    throw new Error(
      `Unknown command keys ${JSON.stringify(extras)} at ${pathLabel(path)}`,
    );
  }

  const kind = commandKey;
  if (repeat === undefined) {
    return { kind, arg };
  }

  return { kind, arg, repeat };
}

function parseRepeat(value: unknown, path: string[]): RepeatValue | undefined {
  if (value === undefined || value === null) {
    return undefined;
  }
  if (isRepeatValue(value)) {
    return value;
  }
  throw new Error(
    `Invalid repeat value ${JSON.stringify(value)} at ${pathLabel(path)}`,
  );
}

function pathLabel(path: string[]): string {
  if (path.length === 0) {
    return "root";
  }
  return path.map((item) => JSON.stringify(item)).join(" -> ");
}

function isPlainObject(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
