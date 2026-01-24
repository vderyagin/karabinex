import { describe, expect, test } from "bun:test";
import { readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import {
  loadKeyCodesFromFile,
  parseJsonConfig,
  toManipulators,
} from "../src/index";

type JsonMap = Record<string, unknown>;

type Multiset = Map<string, number>;

type FixtureNode =
  | { type: "command"; manipulator: JsonMap }
  | {
      type: "keymap";
      varName: string;
      enable: JsonMap;
      children: Multiset;
      captures: Multiset;
      disable: JsonMap;
    };

const fixturesDir = join("test", "fixtures");
const keyCodes = loadKeyCodesFromFile(
  join("data", "simple_modifications.json"),
);

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

function toMultiset(nodes: FixtureNode[]): Multiset {
  const counts = new Map<string, number>();
  for (const node of nodes) {
    const key = stableSerialize(nodeToComparable(node));
    counts.set(key, (counts.get(key) ?? 0) + 1);
  }
  return counts;
}

function toMultisetFromObjects(items: JsonMap[]): Multiset {
  const counts = new Map<string, number>();
  for (const item of items) {
    const key = stableSerialize(item);
    counts.set(key, (counts.get(key) ?? 0) + 1);
  }
  return counts;
}

function nodeToComparable(node: FixtureNode): JsonMap {
  if (node.type === "command") {
    return { type: "command", manipulator: node.manipulator };
  }

  return {
    type: "keymap",
    varName: node.varName,
    enable: node.enable,
    children: multisetToObject(node.children),
    captures: multisetToObject(node.captures),
    disable: node.disable,
  };
}

function multisetToObject(multiset: Multiset): JsonMap {
  return Object.fromEntries(
    [...multiset.entries()].sort(([a], [b]) => a.localeCompare(b)),
  );
}

function parseNodes(manipulators: JsonMap[]): Multiset {
  const [nodes] = parseSequence(manipulators);
  return toMultiset(nodes);
}

function parseSequence(manipulators: JsonMap[]): [FixtureNode[], JsonMap[]] {
  const nodes: FixtureNode[] = [];
  let rest = manipulators;

  while (rest.length > 0) {
    const current = rest[0];
    if (!current) {
      break;
    }
    const tail = rest.slice(1);
    const varName = enableVarName(current);

    if (!varName) {
      nodes.push({
        type: "command",
        manipulator: normalizeManipulator(current),
      });
      rest = tail;
      continue;
    }

    const [node, remaining] = parseKeymap(current, tail, varName);
    nodes.push(node);
    rest = remaining;
  }

  return [nodes, []];
}

function parseKeymap(
  enableManipulator: JsonMap,
  rest: JsonMap[],
  varName: string,
): [FixtureNode, JsonMap[]] {
  const [children, remaining, captures] = parseChildrenAndCaptures(
    rest,
    varName,
    [],
    [],
  );

  if (remaining.length === 0) {
    throw new Error(`Missing disable for ${varName}`);
  }

  const disableManipulator = remaining[0];
  if (!disableManipulator) {
    throw new Error(`Missing disable for ${varName}`);
  }
  const tail = remaining.slice(1);
  if (disableVarName(disableManipulator) !== varName) {
    throw new Error(`Expected disable for ${varName}`);
  }

  return [
    {
      type: "keymap",
      varName,
      enable: normalizeManipulator(enableManipulator),
      children: toMultiset(children),
      captures: toMultisetFromObjects(
        captures.map((capture) => normalizeManipulator(capture)),
      ),
      disable: normalizeManipulator(disableManipulator),
    },
    tail,
  ];
}

function parseChildrenAndCaptures(
  manipulators: JsonMap[],
  varName: string,
  childrenAcc: FixtureNode[],
  capturesAcc: JsonMap[],
): [FixtureNode[], JsonMap[], JsonMap[]] {
  if (manipulators.length === 0) {
    throw new Error(`Missing disable for ${varName}`);
  }

  const current = manipulators[0];
  if (!current) {
    throw new Error(`Missing disable for ${varName}`);
  }
  const rest = manipulators.slice(1);

  if (disableVarName(current) === varName) {
    return [childrenAcc, manipulators, capturesAcc];
  }

  if (captureVarName(current) === varName) {
    const [captures, remaining] = parseCaptures(
      manipulators,
      varName,
      capturesAcc,
    );
    return [childrenAcc, remaining, captures];
  }

  const childVarName = enableVarName(current);
  if (childVarName) {
    const [childNode, remaining] = parseKeymap(current, rest, childVarName);
    return parseChildrenAndCaptures(
      remaining,
      varName,
      [...childrenAcc, childNode],
      capturesAcc,
    );
  }

  const childNode: FixtureNode = {
    type: "command",
    manipulator: normalizeManipulator(current),
  };
  return parseChildrenAndCaptures(
    rest,
    varName,
    [...childrenAcc, childNode],
    capturesAcc,
  );
}

function parseCaptures(
  manipulators: JsonMap[],
  varName: string,
  acc: JsonMap[],
): [JsonMap[], JsonMap[]] {
  if (manipulators.length === 0) {
    throw new Error(`Missing disable for ${varName}`);
  }

  const current = manipulators[0];
  if (!current) {
    throw new Error(`Missing disable for ${varName}`);
  }
  const rest = manipulators.slice(1);

  if (captureVarName(current) === varName) {
    return parseCaptures(rest, varName, [
      ...acc,
      normalizeManipulator(current),
    ]);
  }

  if (disableVarName(current) === varName) {
    return [acc, manipulators];
  }

  throw new Error(`Unexpected manipulator in capture block for ${varName}`);
}

function enableVarName(manipulator: JsonMap): string | null {
  const to = manipulator.to;
  if (!Array.isArray(to)) {
    return null;
  }

  for (const clause of to) {
    const setVar = (clause as JsonMap).set_variable as JsonMap | undefined;
    if (
      setVar &&
      typeof setVar.name === "string" &&
      typeof setVar.value === "number"
    ) {
      return setVar.name as string;
    }
  }

  return null;
}

function disableVarName(manipulator: JsonMap): string | null {
  const from = manipulator.from as JsonMap | undefined;
  const conditions = manipulator.conditions;
  const to = manipulator.to;

  if (
    !from ||
    from.any !== "key_code" ||
    !Array.isArray(conditions) ||
    !Array.isArray(to)
  ) {
    return null;
  }

  const names = conditions
    .filter((condition) => variableIfValue(condition, 1))
    .map((condition) => (condition as JsonMap).name)
    .filter((name): name is string => typeof name === "string");

  const unique = [...new Set(names)];
  if (unique.length !== 1) {
    return null;
  }

  const name = unique[0];
  if (!name) {
    return null;
  }
  const unset = to.some((clause) => {
    const setVar = (clause as JsonMap).set_variable as JsonMap | undefined;
    return setVar?.name === name && setVar?.type === "unset";
  });

  return unset ? name : null;
}

function captureVarName(manipulator: JsonMap): string | null {
  const from = manipulator.from as JsonMap | undefined;
  const to = manipulator.to;
  const conditions = manipulator.conditions;

  if (
    !from ||
    typeof from.key_code !== "string" ||
    !Array.isArray(to) ||
    !Array.isArray(conditions)
  ) {
    return null;
  }

  if (to.length !== 1) {
    return null;
  }

  const toClause = to[0] as JsonMap;
  if (toClause.key_code !== from.key_code) {
    return null;
  }

  const code = from.key_code;
  if (!code.startsWith("left_") && !code.startsWith("right_")) {
    return null;
  }

  const names = conditions
    .filter((condition) => variableIfValue(condition, 1))
    .map((condition) => (condition as JsonMap).name)
    .filter((name): name is string => typeof name === "string");

  const unique = [...new Set(names)];
  if (unique.length !== 1) {
    return null;
  }

  return unique[0] ?? null;
}

function variableIfValue(condition: unknown, expected: number): boolean {
  const data = condition as JsonMap;
  return (
    data.type === "variable_if" &&
    typeof data.name === "string" &&
    data.value === expected
  );
}

function compareMultisets(actual: Multiset, expected: Multiset): void {
  if (actual.size === expected.size) {
    let match = true;
    for (const [key, count] of expected.entries()) {
      if (actual.get(key) !== count) {
        match = false;
        break;
      }
    }
    if (match) {
      return;
    }
  }

  const missing = multisetDiff(expected, actual);
  const extra = multisetDiff(actual, expected);

  const lines: string[] = [];
  appendDiff(lines, "missing", missing);
  appendDiff(lines, "extra", extra);

  throw new Error(lines.join("\n"));
}

function multisetDiff(left: Multiset, right: Multiset): Multiset {
  const result = new Map<string, number>();
  for (const [key, count] of left.entries()) {
    const remaining = count - (right.get(key) ?? 0);
    if (remaining > 0) {
      result.set(key, remaining);
    }
  }
  return result;
}

function appendDiff(lines: string[], label: string, diff: Multiset): void {
  if (diff.size === 0) {
    return;
  }

  const entries = [...diff.entries()]
    .map(([item, count]) => `${count}x ${item}`)
    .join("\n  ");
  lines.push(`${label}:\n  ${entries}`);
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

      const actualNodes = parseNodes(actual);
      const expectedNodes = parseNodes(expected);

      try {
        compareMultisets(actualNodes, expectedNodes);
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        throw new Error(`fixture mismatch: ${base}\n${message}`);
      }
    }
  });
});
