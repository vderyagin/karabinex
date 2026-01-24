import type { Chord } from "./chord";
import type { Command } from "./command";

export class Keymap {
  readonly chord: Chord;
  readonly children: ReadonlyArray<Keymap | Command>;
  hook?: Command;

  constructor(chord: Chord, children: ReadonlyArray<Keymap | Command>) {
    this.chord = chord;
    this.children = children;
  }

  addHook(hook: Command): void {
    this.hook = hook;
  }
}
