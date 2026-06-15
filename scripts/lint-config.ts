import { lintComplexModifications } from "../src/karabinerCli";
import { resolvePathArg } from "../src/pathArg";

const projectRoot = process.cwd();
const configPath = resolvePathArg(
  process.argv.slice(2),
  projectRoot,
  "karabinex.json",
);

lintComplexModifications(configPath);
