import type { Key } from "./key";

export class Chord {
  keys: Key[];

  constructor(keys: Key[] = []) {
    this.keys = keys;
  }

  static empty(): Chord {
    return new Chord();
  }

  append(key: Key): Chord {
    return new Chord([...this.keys, key]);
  }

  last(): Key {
    if (this.keys.length === 0) {
      throw new Error("Chord has no keys");
    }
    return this.keys[this.keys.length - 1];
  }

  prefix(): Chord {
    if (this.keys.length === 0) {
      throw new Error("Chord has no keys");
    }
    return new Chord(this.keys.slice(0, -1));
  }

  isSingleton(): boolean {
    return this.keys.length === 1;
  }

  varName(): string {
    const parts = this.keys.map((key) => key.readableName()).join("_");
    return `karabinex_${parts}_map`;
  }

  prefixVarName(): string {
    if (this.isSingleton()) {
      throw new Error("Prefix var name not available for singleton chord");
    }
    return this.prefix().varName();
  }
}
