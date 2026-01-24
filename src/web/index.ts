import { buildConfigJson } from "./buildConfig";

type ElementConstructor<T extends HTMLElement> = new (...args: never[]) => T;

function getElement<T extends HTMLElement>(
  id: string,
  ctor: ElementConstructor<T>,
): T {
  const element = document.getElementById(id);
  if (!element) {
    throw new Error(`Missing element #${id}`);
  }
  if (!(element instanceof ctor)) {
    throw new Error(`Element #${id} is not a ${ctor.name}`);
  }
  return element;
}

const input = getElement("rules", HTMLTextAreaElement);
const output = getElement("output", HTMLTextAreaElement);
const status = getElement("status", HTMLDivElement);
const transformButton = getElement("transform", HTMLButtonElement);
const formatButton = getElement("format", HTMLButtonElement);
const copyButton = getElement("copy", HTMLButtonElement);

function setStatus(message: string, kind: "ok" | "error") {
  status.textContent = message;
  status.dataset.state = kind;
}

function runTransform() {
  try {
    const configJson = buildConfigJson(input.value);
    output.value = configJson;
    setStatus("Generated karabiner config.", "ok");
    refreshCopyState();
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    output.value = "";
    setStatus(message, "error");
    refreshCopyState();
  }
}

function isValidJson(value: string) {
  if (!value.trim()) {
    return false;
  }

  try {
    JSON.parse(value);
    return true;
  } catch {
    return false;
  }
}

function refreshFormatState() {
  formatButton.disabled = !isValidJson(input.value);
}

function refreshCopyState() {
  copyButton.disabled = output.value.trim().length === 0;
}

function formatInput() {
  try {
    const parsed = JSON.parse(input.value);
    input.value = `${JSON.stringify(parsed, null, 2)}\n`;
    setStatus("Formatted input.", "ok");
    refreshFormatState();
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    setStatus(message, "error");
  }
}

async function copyOutput() {
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

formatButton.addEventListener("click", (event) => {
  event.preventDefault();
  formatInput();
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

input.addEventListener("input", () => {
  refreshFormatState();
});

refreshFormatState();
refreshCopyState();
