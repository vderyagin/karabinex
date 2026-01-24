import type { KeyCodes } from "../src/keyCodes";

export function makeKeyCodes(options?: {
  regular?: string[];
  consumer?: string[];
  pointer?: string[];
}): KeyCodes {
  return {
    regular: new Set(
      options?.regular ?? [
        "a",
        "b",
        "c",
        "x",
        "y",
        "z",
        "left_control",
        "right_control",
      ],
    ),
    consumer: new Set(options?.consumer ?? ["volume_up"]),
    pointer: new Set(options?.pointer ?? ["button1"]),
  };
}
