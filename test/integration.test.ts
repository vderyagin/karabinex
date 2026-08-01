import { describe, expect, test } from "bun:test";
import { readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { parseJsonConfig, toManipulators } from "../src/index";
import { makeKeyCodes } from "./testUtils";

type JsonMap = Record<string, unknown>;

const fixturesDir = join("test", "fixtures");
const keyCodes = makeKeyCodes({
  regular: [
    "a",
    "b",
    "c",
    "d",
    "e",
    "f",
    "g",
    "h",
    "i",
    "j",
    "k",
    "l",
    "w",
    "x",
    "y",
    "z",
    "left_control",
    "right_control",
    "left_shift",
    "right_shift",
    "left_option",
    "right_option",
  ],
});

function normalizeManipulator(manipulator: JsonMap): JsonMap {
  const normalized = normalizeTerm(manipulator) as JsonMap;

  if (Array.isArray(normalized.conditions)) {
    const conditions = normalized.conditions.map((condition) =>
      normalizeTerm(condition),
    );
    normalized.conditions = toMultisetObject(conditions);
  }

  const from = normalized.from as JsonMap | undefined;
  const modifiers = from?.modifiers as JsonMap | undefined;
  const mandatory = modifiers?.mandatory;
  if (Array.isArray(mandatory)) {
    const sorted = [...mandatory].map((value) => String(value)).sort();
    if (modifiers) {
      modifiers.mandatory = sorted;
    }
  }

  return normalized;
}

function normalizeTerm(value: unknown): unknown {
  if (Array.isArray(value)) {
    return value.map((item) => normalizeTerm(item));
  }

  if (value && typeof value === "object") {
    const obj = value as Record<string, unknown>;
    const entries = Object.entries(obj).map(
      ([key, val]) => [key, normalizeTerm(val)] as const,
    );
    return Object.fromEntries(entries);
  }

  return value;
}

function toMultisetObject(items: unknown[]): JsonMap {
  const counts = new Map<string, number>();
  for (const item of items) {
    const key = stableSerialize(item);
    counts.set(key, (counts.get(key) ?? 0) + 1);
  }

  return Object.fromEntries(
    [...counts.entries()].sort(([a], [b]) => a.localeCompare(b)),
  );
}

function stableSerialize(value: unknown): string {
  if (value === null || value === undefined) {
    return JSON.stringify(value);
  }

  if (Array.isArray(value)) {
    return `[${value.map(stableSerialize).join(",")}]`;
  }

  if (typeof value === "object") {
    const obj = value as Record<string, unknown>;
    const keys = Object.keys(obj).sort();
    const body = keys
      .map((key) => `${JSON.stringify(key)}:${stableSerialize(obj[key])}`)
      .join(",");
    return `{${body}}`;
  }

  return JSON.stringify(value);
}

describe("fixtures", () => {
  const inputs = readdirSync(fixturesDir).filter((file) =>
    file.endsWith("_input.json"),
  );

  test("fixture outputs", () => {
    expect(inputs.length).toBeGreaterThan(0);

    for (const inputFile of inputs) {
      const base = inputFile.replace(/_input\.json$/, "");
      const inputPath = join(fixturesDir, inputFile);
      const expectedPath = join(fixturesDir, `${base}_expected.json`);

      const input = readFileSync(inputPath, "utf8");
      const expected = JSON.parse(
        readFileSync(expectedPath, "utf8"),
      ) as JsonMap[];

      const defs = parseJsonConfig(input);
      const actual = JSON.parse(
        JSON.stringify(toManipulators(defs, keyCodes)),
      ) as JsonMap[];

      const normalizedActual = actual.map((item) => normalizeManipulator(item));
      const normalizedExpected = expected.map((item) =>
        normalizeManipulator(item),
      );

      expect(normalizedActual).toEqual(normalizedExpected);
    }
  });
});
