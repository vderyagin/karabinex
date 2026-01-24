import type { Chord } from "./chord";

export type CommandKind = "app" | "quit" | "kill" | "sh" | "raycast";
export type RepeatValue = "key" | "keymap";

export type CommandDef = {
  kind: CommandKind;
  arg: string;
  repeat?: RepeatValue;
};

export class Command {
  chord: Chord;
  kind: CommandKind;
  arg: string;
  repeat: boolean;

  constructor(chord: Chord, kind: CommandKind, arg: string, repeat = false) {
    this.chord = chord;
    this.kind = kind;
    this.arg = arg;
    this.repeat = repeat;
  }
}
