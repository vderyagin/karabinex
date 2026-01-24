import { describe, expect, test } from "bun:test";
import { Chord } from "../../src/chord";
import { Command } from "../../src/command";
import { Key } from "../../src/key";
import { Keymap } from "../../src/keymap";
import {
  captureOtherChords,
  commandString,
  generate,
  toManipulator,
} from "../../src/manipulator";
import { makeKeyCodes } from "../testUtils";

describe("manipulator", () => {
  test("commandString formats commands", () => {
    expect(commandString("app", "Safari")).toBe("open -a 'Safari'");
    expect(commandString("raycast", "confetti")).toBe(
      "open raycast://confetti",
    );
    expect(commandString("quit", "Slack")).toBe(
      "osascript -e 'quit app \"Slack\"'",
    );
    expect(commandString("kill", "Slack")).toBe("killall -SIGKILL 'Slack'");
    expect(commandString("sh", "echo hi")).toBe("echo hi");
  });

  test("invoke command manipulator respects repeat", () => {
    const codes = makeKeyCodes();
    const chord = Chord.empty()
      .append(Key.parse("C-a", codes))
      .append(Key.parse("b", codes));
    const command = new Command(chord, "sh", "echo hi", false);
    const manipulator = toManipulator(generate(command)[0]);

    const conditions = manipulator.conditions ?? [];
    expect(conditions.length).toBeGreaterThan(0);
    expect(
      (manipulator.to ?? []).some(
        (clause) => (clause as { set_variable?: unknown }).set_variable,
      ),
    ).toBe(true);
  });

  test("captureOtherChords registers other keymaps", () => {
    const codes = makeKeyCodes();
    const keymapA = new Keymap(Chord.empty().append(Key.parse("C-a", codes)), [
      new Command(
        Chord.empty()
          .append(Key.parse("C-a", codes))
          .append(Key.parse("b", codes)),
        "sh",
        "echo a",
      ),
    ]);
    const keymapB = new Keymap(Chord.empty().append(Key.parse("C-b", codes)), [
      new Command(
        Chord.empty()
          .append(Key.parse("C-b", codes))
          .append(Key.parse("c", codes)),
        "sh",
        "echo b",
      ),
    ]);

    const generated = [...generate(keymapA), ...generate(keymapB)];
    const updated = captureOtherChords(generated);
    const enableKeymaps = updated.filter(
      (item) => (item as { otherChords?: unknown }).otherChords,
    ) as {
      otherChords: unknown[];
    }[];

    expect(enableKeymaps.length).toBe(2);
    expect(enableKeymaps[0].otherChords.length).toBeGreaterThan(0);
    expect(enableKeymaps[1].otherChords.length).toBeGreaterThan(0);
  });
});
