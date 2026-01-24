import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";

const projectRoot = process.cwd();
const entrypoint = join(projectRoot, "src", "web", "index.ts");
const templatePath = join(projectRoot, "web", "index.template.html");
const outputPath = join(projectRoot, "web", "index.html");
const placeholder = "<!-- INLINE_SCRIPT -->";

const result = await Bun.build({
  entrypoints: [entrypoint],
  target: "browser",
  format: "iife",
  minify: true,
  sourcemap: "none",
  splitting: false,
  write: false,
});

if (!result.success) {
  const messages = result.logs.map((log) => log.message).join("\n");
  throw new Error(`build failed:\n${messages}`);
}

const output = result.outputs[0];
if (!output) {
  throw new Error("build produced no output");
}

const js = await output.text();
const template = readFileSync(templatePath, "utf8");

if (!template.includes(placeholder)) {
  throw new Error(`missing placeholder ${placeholder} in ${templatePath}`);
}

const inlineScript = `<script>${js}</script>`;
const html = minifyHtml(template.replace(placeholder, inlineScript));

mkdirSync(dirname(outputPath), { recursive: true });
writeFileSync(outputPath, html);

function minifyHtml(input: string): string {
  const placeholders: string[] = [];
  const preserved = input.replace(/<textarea[\s\S]*?<\/textarea>/g, (match) => {
    const token = `__TEXTAREA_${placeholders.length}__`;
    placeholders.push(match);
    return token;
  });

  let result = preserved.replace(/>\s+</g, "><").trim();
  for (const [index, textarea] of placeholders.entries()) {
    result = result.replace(`__TEXTAREA_${index}__`, textarea);
  }
  return result;
}
