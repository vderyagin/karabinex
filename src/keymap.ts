import type { Chord } from "./chord";
import type { Command } from "./command";

export class Keymap {
  chord: Chord;
  children: Array<Keymap | Command>;
  hook?: Command;

  constructor(chord: Chord, children: Array<Keymap | Command>) {
    this.chord = chord;
    this.children = children;
  }

  addHook(hook: Command): void {
    this.hook = hook;
  }
}
