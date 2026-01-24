import { describe, expect, test } from "bun:test";
import { Key } from "../../src/key";
import { makeKeyCodes } from "../testUtils";

describe("key", () => {
  test("parses modifiers and code", () => {
    const codes = makeKeyCodes();
    const key = Key.parse("C-S-a", codes);
    expect(key.code.code).toBe("a");
    expect(key.modifiers).toEqual(["control", "shift"]);
  });

  test("parses Meh alias", () => {
    const codes = makeKeyCodes();
    const key = Key.parse("Meh-a", codes);
    expect(key.modifiers).toEqual(["option", "control", "shift"]);
    expect(key.readableName()).toBe("meh-a");
  });

  test("parses Hyper alias", () => {
    const codes = makeKeyCodes();
    const key = Key.parse("H-a", codes);
    expect(key.modifiers).toEqual(["command", "option", "control", "shift"]);
    expect(key.readableName()).toBe("hyper-a");
  });

  test("rejects duplicate modifiers", () => {
    const codes = makeKeyCodes();
    expect(() => Key.parse("C-C-a", codes)).toThrow();
  });

  test("codeSpec selects key type", () => {
    const codes = makeKeyCodes({
      regular: ["a"],
      consumer: ["volume_up"],
      pointer: ["button1"],
    });
    const regular = Key.parse("a", codes);
    const consumer = Key.parse("volume_up", codes);
    const pointer = Key.parse("button1", codes);

    expect(regular.codeSpec()).toEqual({ key_code: "a" });
    expect(consumer.codeSpec()).toEqual({ consumer_key_code: "volume_up" });
    expect(pointer.codeSpec()).toEqual({ pointing_button: "button1" });
  });

  test("rejects unknown key code", () => {
    const codes = makeKeyCodes();
    expect(() => Key.parse("unknown", codes)).toThrow();
  });
});
