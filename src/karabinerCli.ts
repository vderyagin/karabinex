import { spawnSync } from "node:child_process";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

export function lintComplexModifications(path: string): void {
  const karabinerBin =
    "/Library/Application Support/org.pqrs/Karabiner-Elements/bin";
  const env = {
    ...process.env,
    PATH: `${karabinerBin}:${process.env.PATH ?? ""}`,
  };

  const result = spawnSync(
    "karabiner_cli",
    ["--lint-complex-modifications", path],
    {
      stdio: "inherit",
      env,
    },
  );

  if (result.error) {
    throw result.error;
  }

  if (result.status !== 0) {
    throw new Error("karabiner_cli lint failed");
  }
}

export function lintComplexModificationsJson(json: string): void {
  const dir = mkdtempSync(join(tmpdir(), "karabinex-"));
  const path = join(dir, "karabinex.json");

  try {
    writeFileSync(path, json);
    lintComplexModifications(path);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}
