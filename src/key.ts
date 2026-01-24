import type { KeyCodes } from "./keyCodes";

export type Modifier = "command" | "option" | "control" | "shift";
export type KeyCodeType = "regular" | "consumer" | "pointer";

export type KeyCode = {
  type: KeyCodeType;
  code: string;
};

export type KeyCodeSpec =
  | { key_code: string }
  | { consumer_key_code: string }
  | { pointing_button: string };

const modifierOrder: Modifier[] = ["command", "option", "control", "shift"];
const hyperSymbol = "\u2726";
const commandSymbol = "\u2318";
const optionSymbol = "\u2325";
const hyperPrefix = `${hyperSymbol}-`;
const commandPrefix = `${commandSymbol}-`;
const optionPrefix = `${optionSymbol}-`;

export class Key {
  readonly raw: string;
  readonly code: KeyCode;
  readonly modifiers: ReadonlyArray<Modifier>;
  private readonly modifierSet: ReadonlySet<Modifier>;

  private constructor(
    raw: string,
    code: KeyCode,
    modifiers: Modifier[],
    modifierSet: Set<Modifier>,
  ) {
    this.raw = raw;
    this.code = code;
    this.modifiers = modifiers;
    this.modifierSet = modifierSet;
  }

  static parse(raw: string, keyCodes: KeyCodes): Key {
    let rest = raw;
    const modifiers: Modifier[] = [];
    const modifierSet = new Set<Modifier>();

    const addModifier = (modifier: Modifier) => {
      if (modifierSet.has(modifier)) {
        throw new Error(`invalid key specification: ${raw}`);
      }
      modifierSet.add(modifier);
      modifiers.push(modifier);
    };

    while (true) {
      if (rest.startsWith("H-")) {
        rest = `${hyperPrefix}${rest.slice(2)}`;
        continue;
      }
      if (rest.startsWith(hyperPrefix)) {
        rest = `${commandPrefix}M-C-S-${rest.slice(hyperPrefix.length)}`;
        continue;
      }
      if (rest.startsWith("Meh-")) {
        rest = `M-C-S-${rest.slice(4)}`;
        continue;
      }
      if (rest.startsWith(commandPrefix)) {
        addModifier("command");
        rest = rest.slice(commandPrefix.length);
        continue;
      }
      if (rest.startsWith("M-")) {
        rest = `${optionPrefix}${rest.slice(2)}`;
        continue;
      }
      if (rest.startsWith(optionPrefix)) {
        addModifier("option");
        rest = rest.slice(optionPrefix.length);
        continue;
      }
      if (rest.startsWith("^-")) {
        rest = `C-${rest.slice(2)}`;
        continue;
      }
      if (rest.startsWith("C-")) {
        addModifier("control");
        rest = rest.slice(2);
        continue;
      }
      if (rest.startsWith("S-")) {
        addModifier("shift");
        rest = rest.slice(2);
        continue;
      }
      break;
    }

    let codeType: KeyCodeType;
    if (keyCodes.regular.has(rest)) {
      codeType = "regular";
    } else if (keyCodes.consumer.has(rest)) {
      codeType = "consumer";
    } else if (keyCodes.pointer.has(rest)) {
      codeType = "pointer";
    } else {
      throw new Error(`key code not recognized: ${raw}`);
    }

    return new Key(raw, { type: codeType, code: rest }, modifiers, modifierSet);
  }

  hasModifiers(): boolean {
    return this.modifiers.length > 0;
  }

  codeSpec(): KeyCodeSpec {
    if (this.code.type === "regular") {
      return { key_code: this.code.code };
    }
    if (this.code.type === "consumer") {
      return { consumer_key_code: this.code.code };
    }
    return { pointing_button: this.code.code };
  }

  modifierSetKey(): string {
    return modifierOrder
      .filter((modifier) => this.modifierSet.has(modifier))
      .join("|");
  }

  readableName(): string {
    const modifierSetKey = this.modifierSetKey();
    const hyperKey = modifierOrder.join("|");
    const mehKey = ["option", "control", "shift"].join("|");

    let prefix: string;
    if (modifierSetKey === hyperKey) {
      prefix = "hyper-";
    } else if (modifierSetKey === mehKey) {
      prefix = "meh-";
    } else {
      prefix = this.modifiers.map((modifier) => `${modifier}-`).join("");
    }

    return `${prefix}${this.code.code}`;
  }
}
