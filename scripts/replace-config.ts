import { copyFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { homedir } from "node:os";
import { spawnSync } from "node:child_process";
import { updateKarabinerConfig } from "../src/karabinerConfig";
import { writeConfig } from "../src/writeConfig";

const projectRoot = process.cwd();
const rulesPath = join(projectRoot, "rules.json");
const outputPath = join(projectRoot, "karabinex.json");
const keyCodesPath = join(projectRoot, "data", "simple_modifications.json");
const assetPath = join(
  homedir(),
  ".config/karabiner/assets/complex_modifications/karabinex.json",
);

writeConfig({
  rulesPath,
  outputPath,
  keyCodesPath,
});

lintConfig(outputPath);

mkdirSync(dirname(assetPath), { recursive: true });
copyFileSync(outputPath, assetPath);

updateKarabinerConfig(outputPath);

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
