import { join } from "node:path";
import { writeConfig } from "../src/writeConfig";

const projectRoot = process.cwd();

writeConfig({
  rulesPath: join(projectRoot, "rules.json"),
  outputPath: join(projectRoot, "karabinex.json"),
  keyCodesPath: join(projectRoot, "priv", "simple_modifications.json"),
});
