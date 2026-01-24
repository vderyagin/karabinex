import { spawnSync } from "node:child_process";
import { join } from "node:path";

const projectRoot = process.cwd();
const configPath = join(projectRoot, "karabinex.json");

lintConfig(configPath);

function lintConfig(path: string): void {
  const karabinerBin = "/Library/Application Support/org.pqrs/Karabiner-Elements/bin";
  const env = {
    ...process.env,
    PATH: `${karabinerBin}:${process.env.PATH ?? ""}`,
  };

  const result = spawnSync("karabiner_cli", ["--lint-complex-modifications", path], {
    stdio: "inherit",
    env,
  });

  if (result.error) {
    throw result.error;
  }

  if (result.status !== 0) {
    throw new Error("karabiner_cli lint failed");
  }
}
