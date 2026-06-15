import { join, resolve } from "node:path";

export function resolvePathArg(
  args: string[],
  cwd: string,
  defaultRelativePath: string,
): string {
  const [providedPath] = args;

  if (!providedPath) {
    return join(cwd, defaultRelativePath);
  }

  return resolve(cwd, providedPath);
}
