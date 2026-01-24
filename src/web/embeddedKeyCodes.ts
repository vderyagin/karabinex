import keyCodesData from "../../data/simple_modifications.json";
import { parseKeyCodes, type KeyCodes } from "../keyCodes";

export const embeddedKeyCodes: KeyCodes = parseKeyCodes(keyCodesData);
