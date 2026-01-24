import { readFileSync } from "node:fs";
import { parseKeyCodes, type KeyCodes } from "./keyCodes";

export function loadKeyCodesFromFile(path: string): KeyCodes {
  const data = JSON.parse(readFileSync(path, "utf8"));
  return parseKeyCodes(data);
}
