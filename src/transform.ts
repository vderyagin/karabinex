import { preprocess } from "./config";
import { parseDefinitions } from "./definitions";
import type { KeymapDef } from "./jsonConfig";
import type { KeyCodes } from "./keyCodes";
import { captureOtherChords, generate, toManipulator } from "./manipulator";
import { validate } from "./validator";

export function toManipulators(defs: KeymapDef, keyCodes: KeyCodes) {
  const processed = preprocess(defs);
  validate(processed, keyCodes);
  const parsed = parseDefinitions(processed, keyCodes);
  const generated = parsed.flatMap((item) => generate(item));
  const withChords = captureOtherChords(generated);
  return withChords.map((item) => toManipulator(item));
}
