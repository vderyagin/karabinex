import keyCodesData from "../../data/simple_modifications.json";
import { type KeyCodes, parseKeyCodes } from "../keyCodes";

export const embeddedKeyCodes: KeyCodes = parseKeyCodes(keyCodesData);
