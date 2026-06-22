import { describe, expect, test } from "bun:test";
import { Chord } from "../src/chord";
import { Command } from "../src/command";
import { Key } from "../src/key";
import { Keymap } from "../src/keymap";
import {
  captureOtherChords,
  captureTopLevelKeymaps,
  commandString,
  generate,
  toManipulator,
} from "../src/manipulator";
import { makeKeyCodes } from "./testUtils";

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
    const generated = generate(command);
    const first = generated[0];
    if (!first) {
      throw new Error("Expected generated manipulator");
    }
    const manipulator = toManipulator(first);

    const conditions = manipulator.conditions ?? [];
    expect(conditions.length).toBeGreaterThan(0);
    expect(
      (manipulator.to ?? []).some(
        (clause: Record<string, unknown>) =>
          (clause as { set_variable?: unknown }).set_variable,
      ),
    ).toBe(true);
  });

  test("regular keymap reset swallows unmatched keys", () => {
    const codes = makeKeyCodes();
    const prefix = Chord.empty().append(Key.parse("C-a", codes));
    const keymap = new Keymap(prefix, [
      new Command(prefix.append(Key.parse("b", codes)), "sh", "echo hi"),
    ]);
    const manipulators = generate(keymap).map((item) => toManipulator(item));
    const reset = manipulators.find(
      (manipulator) =>
        (manipulator.from as { any?: string }).any === "key_code",
    );

    expect(reset?.from).toEqual({ any: "key_code" });
    expect(reset?.to).not.toContainEqual({ from_event: true });
  });

  test("repeat keymap resets with from_event pass-through", () => {
    const codes = makeKeyCodes();
    const prefix = Chord.empty().append(Key.parse("C-a", codes));
    const keymap = new Keymap(prefix, [
      new Command(prefix.append(Key.parse("b", codes)), "sh", "echo hi", true),
    ]);
    const manipulators = generate(keymap).map((item) => toManipulator(item));
    const passThroughReset = manipulators.find((manipulator) =>
      (manipulator.to ?? []).some(
        (clause: Record<string, unknown>) =>
          (clause as { from_event?: boolean }).from_event === true,
      ),
    );

    expect(passThroughReset?.from).toEqual({
      any: "key_code",
      modifiers: { optional: ["any"] },
    });
    expect(passThroughReset?.to).toContainEqual({
      set_variable: {
        name: "karabinex_control-a_map",
        type: "unset",
      },
    });
    expect(passThroughReset?.to).toContainEqual({ from_event: true });
  });

  test("repeat keymap can switch to a top-level keymap before pass-through reset", () => {
    const codes = makeKeyCodes();
    const prefixA = Chord.empty().append(Key.parse("C-a", codes));
    const prefixB = Chord.empty().append(Key.parse("C-b", codes));
    const nested = prefixA.append(Key.parse("c", codes));
    const keymapA = new Keymap(prefixA, [
      new Keymap(nested, [
        new Command(
          nested.append(Key.parse("c", codes)),
          "sh",
          "echo repeat",
          true,
        ),
      ]),
    ]);
    const keymapB = new Keymap(prefixB, [
      new Command(prefixB.append(Key.parse("y", codes)), "sh", "echo b"),
    ]);
    const generated = captureTopLevelKeymaps(
      captureOtherChords([...generate(keymapA), ...generate(keymapB)]),
    );
    const manipulators = generated.map((item) => toManipulator(item));
    const switchToBIndex = manipulators.findIndex(
      (manipulator) =>
        (manipulator.from as { key_code?: string }).key_code === "b" &&
        (manipulator.conditions ?? []).some(
          (condition) => condition.name === "karabinex_control-a_c_map",
        ),
    );
    const passThroughResetIndex = manipulators.findIndex((manipulator) =>
      (manipulator.to ?? []).some(
        (clause: Record<string, unknown>) =>
          (clause as { from_event?: boolean }).from_event === true,
      ),
    );
    const switchToB = manipulators[switchToBIndex];

    expect(switchToBIndex).toBeGreaterThan(-1);
    expect(passThroughResetIndex).toBeGreaterThan(switchToBIndex);
    expect(switchToB?.to).toContainEqual({
      set_variable: {
        name: "karabinex_control-a_c_map",
        type: "unset",
      },
    });
    expect(switchToB?.to).toContainEqual({
      set_variable: {
        name: "karabinex_control-b_map",
        value: 1,
      },
    });
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
      (item: unknown) => (item as { otherChords?: unknown }).otherChords,
    ) as {
      otherChords: unknown[];
    }[];

    expect(enableKeymaps.length).toBe(2);
    const first = enableKeymaps[0];
    const second = enableKeymaps[1];
    if (!first || !second) {
      throw new Error("Expected two enable keymaps");
    }
    expect(first.otherChords.length).toBeGreaterThan(0);
    expect(second.otherChords.length).toBeGreaterThan(0);
  });
});
