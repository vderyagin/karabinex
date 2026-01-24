import type { Chord } from "./chord";

export const commandKinds = ["app", "quit", "kill", "sh", "raycast"] as const;
export type CommandKind = (typeof commandKinds)[number];

export const repeatValues = ["key", "keymap"] as const;
export type RepeatValue = (typeof repeatValues)[number];

const commandKindSet = new Set<CommandKind>(commandKinds);
const repeatValueSet = new Set<RepeatValue>(repeatValues);

export function isCommandKind(value: string): value is CommandKind {
  return commandKindSet.has(value as CommandKind);
}

export function isRepeatValue(value: unknown): value is RepeatValue {
  return typeof value === "string" && repeatValueSet.has(value as RepeatValue);
}

export type CommandDef = {
  kind: CommandKind;
  arg: string;
  repeat?: RepeatValue;
};

export class Command {
  readonly chord: Chord;
  readonly kind: CommandKind;
  readonly arg: string;
  readonly repeat: boolean;

  constructor(chord: Chord, kind: CommandKind, arg: string, repeat = false) {
    this.chord = chord;
    this.kind = kind;
    this.arg = arg;
    this.repeat = repeat;
  }
}
