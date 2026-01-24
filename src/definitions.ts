import { Chord } from "./chord";
import type { CommandDef } from "./command";
import { Command } from "./command";
import type { Binding, KeymapDef } from "./jsonConfig";
import { KeymapDef as KeymapDefClass } from "./jsonConfig";
import { Key } from "./key";
import type { KeyCodes } from "./keyCodes";
import { Keymap } from "./keymap";

export function parseDefinitions(
  defs: KeymapDef,
  keyCodes: KeyCodes,
  prefix: Chord = Chord.empty(),
): Array<Keymap | Command> {
  const result: Array<Keymap | Command> = [];

  for (const [key, value] of defs.entries) {
    result.push(parseDefinition(key, value, keyCodes, prefix));
  }

  return result;
}

function parseDefinition(
  key: string,
  value: Binding,
  keyCodes: KeyCodes,
  prefix: Chord,
): Keymap | Command {
  if (value instanceof KeymapDefClass) {
    const chord = prefix.append(Key.parse(key, keyCodes));
    const children = parseDefinitions(value, keyCodes, chord);
    const keymap = new Keymap(chord, children);

    if (value.hook) {
      keymap.addHook(commandFromDef(value.hook, chord));
    }

    return keymap;
  }

  return commandFromDef(value, prefix.append(Key.parse(key, keyCodes)));
}

function commandFromDef(def: CommandDef, chord: Chord): Command {
  if (def.repeat === "keymap") {
    return new Command(chord, def.kind, def.arg, true);
  }
  return new Command(chord, def.kind, def.arg, false);
}
