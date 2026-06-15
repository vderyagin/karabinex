import { join } from "node:path";
import { lintComplexModifications } from "../src/karabinerCli";
import { resolvePathArg } from "../src/pathArg";
import { writeConfig } from "../src/writeConfig";

const projectRoot = process.cwd();
const rulesPath = resolvePathArg(process.argv.slice(2), projectRoot, "rules.json");
const outputPath = join(projectRoot, "karabinex.json");

writeConfig({
  rulesPath,
  outputPath,
  keyCodesPath: join(projectRoot, "data", "simple_modifications.json"),
});

lintComplexModifications(outputPath);
