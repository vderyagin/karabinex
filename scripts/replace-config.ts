import { copyFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { homedir } from "node:os";
import { lintComplexModifications } from "../src/karabinerCli";
import { resolvePathArg } from "../src/pathArg";
import { updateKarabinerConfig } from "../src/karabinerConfig";
import { writeConfig } from "../src/writeConfig";

const projectRoot = process.cwd();
const rulesPath = resolvePathArg(process.argv.slice(2), projectRoot, "rules.json");
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

lintComplexModifications(outputPath);

mkdirSync(dirname(assetPath), { recursive: true });
copyFileSync(outputPath, assetPath);

updateKarabinerConfig(outputPath);
