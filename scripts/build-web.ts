import { readFileSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import htmlnano from "htmlnano";
import { transform } from "lightningcss";
import posthtml from "posthtml";
import posthtmlInline from "posthtml-inline";

const projectRoot = process.cwd();
const webDir = join(projectRoot, "web");
const webSrcDir = join(projectRoot, "src", "web");
const entrypoint = join(projectRoot, "src", "web", "index.ts");
const sourceHtmlPath = join(webSrcDir, "index.html");
const sourceCssPath = join(webSrcDir, "index.css");
const bundledJsPath = join(webDir, "karabinex-web.js");
const bundledCssPath = join(webDir, "karabinex-web.css");
const outputHtmlPath = join(webDir, "index.html");

const jsResult = await Bun.build({
  entrypoints: [entrypoint],
  target: "browser",
  format: "iife",
  minify: true,
  sourcemap: "none",
  splitting: false,
  write: false,
});

if (!jsResult.success) {
  const messages = jsResult.logs.map((log) => log.message).join("\n");
  throw new Error(`build failed:\n${messages}`);
}

const jsOutput = jsResult.outputs[0];
if (!jsOutput) {
  throw new Error("build produced no JS output");
}

const js = await jsOutput.text();
writeFileSync(bundledJsPath, js);

try {
  const cssSource = readFileSync(sourceCssPath);
  const cssMinified = transform({
    filename: "index.css",
    code: Buffer.from(cssSource),
    minify: true,
  });
  writeFileSync(bundledCssPath, cssMinified.code);

  const htmlSource = readFileSync(sourceHtmlPath, "utf8");
  const processed = await posthtml([
    posthtmlInline({ root: webDir }),
    htmlnano({ collapseWhitespace: "all", minifyCss: false, minifyJs: false }),
  ]).process(htmlSource, { from: sourceHtmlPath });

  writeFileSync(outputHtmlPath, processed.html);
} finally {
  rmSync(bundledJsPath, { force: true });
  rmSync(bundledCssPath, { force: true });
}
