import type { Chord } from "./chord";
import type { CommandKind } from "./command";
import { Command } from "./command";
import { Key, type KeyCodeSpec, type Modifier } from "./key";
import { Keymap } from "./keymap";

export type Manipulator = {
  type: "basic";
  from: FromClause;
  to?: ToClause[];
  to_after_key_up?: ToClause[];
  conditions?: Condition[];
};

type ModifierSpec = { mandatory: Modifier[] };

type FromClause =
  | (KeyCodeSpec & { modifiers?: ModifierSpec })
  | { any: "key_code" };

type SetVariableClause =
  | { set_variable: { name: string; value: number } }
  | { set_variable: { name: string; type: "unset" } };

type ToClause =
  | { key_code: string }
  | { shell_command: string }
  | SetVariableClause;

type Condition = { type: "variable_if"; name: string; value: number };

type FromSpec = Key | "any" | KeyCodeSpec;

function manipulate(fromSpec: FromSpec): Manipulator {
  return { type: "basic", from: buildFromClause(fromSpec) };
}

function buildFromClause(fromSpec: FromSpec): FromClause {
  if (fromSpec instanceof Key) {
    if (fromSpec.hasModifiers()) {
      return {
        ...fromSpec.codeSpec(),
        modifiers: { mandatory: [...fromSpec.modifiers] },
      };
    }
    return fromSpec.codeSpec();
  }

  if (fromSpec === "any") {
    return { any: "key_code" };
  }

  return fromSpec;
}

function remap(m: Manipulator, clause: { key_code: string }): Manipulator {
  return appendToClause(m, "to", clause);
}

function runShellCommand(m: Manipulator, cmd: string): Manipulator {
  return appendToClause(m, "to", { shell_command: cmd });
}

function setVariable(m: Manipulator, name: string, value = 1): Manipulator {
  return appendToClause(m, "to", { set_variable: { name, value } });
}

function unsetVariable(m: Manipulator, name: string): Manipulator {
  return appendToClause(m, "to", { set_variable: { name, type: "unset" } });
}

function unsetVariableAfterKeyUp(m: Manipulator, name: string): Manipulator {
  return appendToClause(m, "to_after_key_up", {
    set_variable: { name, type: "unset" },
  });
}

function ifVariable(m: Manipulator, name: string, value = 1): Manipulator {
  return appendCondition(m, { type: "variable_if", name, value });
}

function unlessVariable(m: Manipulator, name: string): Manipulator {
  return ifVariable(m, name, 0);
}

function unlessVariables(m: Manipulator, names: string[]): Manipulator {
  let next = m;
  for (const name of names) {
    next = unlessVariable(next, name);
  }
  return next;
}

function appendToClause(
  m: Manipulator,
  key: "to" | "to_after_key_up",
  clause: ToClause,
): Manipulator {
  const existing = m[key] ?? [];
  return { ...m, [key]: [...existing, clause] };
}

function appendCondition(m: Manipulator, clause: Condition): Manipulator {
  const existing = m.conditions ?? [];
  return { ...m, conditions: [...existing, clause] };
}

export class EnableKeymap {
  readonly keymap: Keymap;
  otherChords: Chord[];

  constructor(keymap: Keymap) {
    this.keymap = keymap;
    this.otherChords = [];
  }

  registerOtherChords(chords: Chord[]): void {
    if (this.keymap.chord.isSingleton()) {
      this.otherChords = chords;
      return;
    }

    const prefixVar = this.keymap.chord.prefixVarName();
    this.otherChords = chords.filter((chord) => chord.varName() !== prefixVar);
  }
}

export class DisableKeymap {
  readonly keymap: Keymap;

  constructor(keymap: Keymap) {
    this.keymap = keymap;
  }
}

export class CaptureModifier {
  readonly modifier: string;
  readonly chord: Chord;
  readonly unsetOnKeyUp: boolean;

  constructor(modifier: string, chord: Chord, unsetOnKeyUp = true) {
    this.modifier = modifier;
    this.chord = chord;
    this.unsetOnKeyUp = unsetOnKeyUp;
  }
}

export class InvokeCommand {
  readonly command: Command;

  constructor(command: Command) {
    this.command = command;
  }
}

export type GeneratedManipulator =
  | EnableKeymap
  | DisableKeymap
  | CaptureModifier
  | InvokeCommand;

export function generate(item: Keymap | Command): GeneratedManipulator[] {
  if (item instanceof Keymap) {
    const children = item.children.flatMap((child) => generate(child));
    const captures = getChildModifiers(item).map(
      ([modifier, unsetOnKeyUp]) =>
        new CaptureModifier(modifier, item.chord, unsetOnKeyUp),
    );
    return [
      new EnableKeymap(item),
      ...children,
      ...captures,
      new DisableKeymap(item),
    ];
  }

  return [new InvokeCommand(item)];
}

function getChildModifiers(keymap: Keymap): Array<[string, boolean]> {
  const repeatable = new Set<Modifier>();
  const modifiers = new Set<Modifier>();

  for (const child of keymap.children) {
    for (const modifier of childModifiers(child)) {
      modifiers.add(modifier);
    }
    for (const modifier of repeatableChildModifiers(child)) {
      repeatable.add(modifier);
    }
  }

  return [...modifiers].flatMap((modifier) => {
    const unsetOnKeyUp = !repeatable.has(modifier);
    return [
      [`left_${modifier}`, unsetOnKeyUp],
      [`right_${modifier}`, unsetOnKeyUp],
    ];
  });
}

function childModifiers(child: Keymap | Command): ReadonlyArray<Modifier> {
  return child.chord.last().modifiers;
}

function repeatableChildModifiers(
  child: Keymap | Command,
): ReadonlyArray<Modifier> {
  if (child instanceof Command && child.repeat) {
    return childModifiers(child);
  }
  return [];
}

export function commandString(kind: CommandKind, arg: string): string {
  switch (kind) {
    case "app":
      return `open -a '${arg}'`;
    case "raycast":
      return `open raycast://${arg}`;
    case "quit":
      return `osascript -e 'quit app "${arg}"'`;
    case "kill":
      return `killall -SIGKILL '${arg}'`;
    case "sh":
      return arg;
  }
}

export function toManipulator(item: GeneratedManipulator): Manipulator {
  if (item instanceof EnableKeymap) {
    return enableKeymapManipulator(item);
  }
  if (item instanceof DisableKeymap) {
    return disableKeymapManipulator(item);
  }
  if (item instanceof CaptureModifier) {
    return captureModifierManipulator(item);
  }
  return invokeCommandManipulator(item);
}

function enableKeymapManipulator(item: EnableKeymap): Manipulator {
  const chord = item.keymap.chord;
  const otherVars = item.otherChords.map((chordItem) => chordItem.varName());
  let m = manipulate(chord.last());
  m = unlessVariables(m, otherVars);

  if (item.keymap.hook) {
    m = ifVariable(m, chord.prefixVarName());
    m = unsetVariable(m, chord.prefixVarName());
    m = setVariable(m, chord.varName());
    return runShellCommand(
      m,
      commandString(item.keymap.hook.kind, item.keymap.hook.arg),
    );
  }

  if (chord.isSingleton()) {
    return setVariable(m, chord.varName());
  }

  m = ifVariable(m, chord.prefixVarName());
  m = unsetVariable(m, chord.prefixVarName());
  return setVariable(m, chord.varName());
}

function disableKeymapManipulator(item: DisableKeymap): Manipulator {
  const varName = item.keymap.chord.varName();
  let m = manipulate("any");
  m = ifVariable(m, varName);
  return unsetVariable(m, varName);
}

function captureModifierManipulator(item: CaptureModifier): Manipulator {
  const varName = item.chord.varName();
  let m = manipulate({ key_code: item.modifier });
  m = remap(m, { key_code: item.modifier });
  m = ifVariable(m, varName);
  if (item.unsetOnKeyUp) {
    m = unsetVariableAfterKeyUp(m, varName);
  }
  return m;
}

function invokeCommandManipulator(item: InvokeCommand): Manipulator {
  const { command } = item;
  const cmd = commandString(command.kind, command.arg);

  if (command.chord.isSingleton()) {
    return runShellCommand(manipulate(command.chord.last()), cmd);
  }

  let m = manipulate(command.chord.last());
  m = ifVariable(m, command.chord.prefixVarName());

  if (!command.repeat) {
    m = unsetVariable(m, command.chord.prefixVarName());
  }

  return runShellCommand(m, cmd);
}

export function captureOtherChords(
  items: GeneratedManipulator[],
): GeneratedManipulator[] {
  const chords = items.filter(isEnableKeymap).map((item) => item.keymap.chord);

  for (const item of items) {
    if (item instanceof EnableKeymap) {
      item.registerOtherChords(chords);
    }
  }

  return items;
}

function isEnableKeymap(item: GeneratedManipulator): item is EnableKeymap {
  return item instanceof EnableKeymap;
}
