import { buildConfigJson } from "./buildConfig";

function getElement<T extends HTMLElement>(id: string): T {
  const element = document.getElementById(id);
  if (!element) {
    throw new Error(`Missing element #${id}`);
  }
  return element as T;
}

const input = getElement<HTMLTextAreaElement>("rules");
const output = getElement<HTMLTextAreaElement>("output");
const status = getElement<HTMLDivElement>("status");
const transformButton = getElement<HTMLButtonElement>("transform");
const copyButton = getElement<HTMLButtonElement>("copy");

function setStatus(message: string, kind: "ok" | "error") {
  status.textContent = message;
  status.dataset.state = kind;
}

function runTransform() {
  try {
    const configJson = buildConfigJson(input.value);
    output.value = configJson;
    setStatus("Generated karabiner config.", "ok");
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    output.value = "";
    setStatus(message, "error");
  }
}

async function copyOutput() {
  if (!output.value) {
    setStatus("Nothing to copy yet.", "error");
    return;
  }

  try {
    await navigator.clipboard.writeText(output.value);
    setStatus("Copied to clipboard.", "ok");
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    setStatus(message, "error");
  }
}

transformButton.addEventListener("click", (event) => {
  event.preventDefault();
  runTransform();
});

copyButton.addEventListener("click", (event) => {
  event.preventDefault();
  void copyOutput();
});

input.addEventListener("keydown", (event) => {
  if ((event.metaKey || event.ctrlKey) && event.key === "Enter") {
    event.preventDefault();
    runTransform();
  }
});
