import { describe, expect, test } from "bun:test";
import { join, resolve } from "node:path";
import { resolvePathArg } from "../src/pathArg";

describe("resolvePathArg", () => {
  test("returns default path when no argument is provided", () => {
    expect(resolvePathArg([], "/tmp/project", "rules.json")).toBe(
      join("/tmp/project", "rules.json"),
    );
  });

  test("resolves a provided relative path against the working directory", () => {
    expect(
      resolvePathArg(["configs/dev.json"], "/tmp/project", "rules.json"),
    ).toBe(resolve("/tmp/project", "configs/dev.json"));
  });

  test("keeps an absolute path absolute", () => {
    expect(
      resolvePathArg(["/tmp/custom.json"], "/tmp/project", "rules.json"),
    ).toBe("/tmp/custom.json");
  });
});
