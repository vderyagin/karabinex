import { describe, expect, test } from "bun:test";
import { Chord } from "../../src/chord";
import { Key } from "../../src/key";
import { makeKeyCodes } from "../testUtils";

describe("chord", () => {
  test("append, last, prefix", () => {
    const codes = makeKeyCodes();
    const a = Key.parse("C-a", codes);
    const b = Key.parse("b", codes);

    const chord = Chord.empty().append(a).append(b);
    expect(chord.last().code.code).toBe("b");
    expect(chord.prefix().last().code.code).toBe("a");
  });

  test("varName and prefixVarName", () => {
    const codes = makeKeyCodes();
    const chord = Chord.empty()
      .append(Key.parse("C-a", codes))
      .append(Key.parse("b", codes));
    expect(chord.varName()).toBe("karabinex_control-a_b_map");
    expect(chord.prefixVarName()).toBe("karabinex_control-a_map");
  });
});
