import { closeBrackets, closeBracketsKeymap } from "@codemirror/autocomplete";
import { defaultKeymap, history, historyKeymap } from "@codemirror/commands";
import { json } from "@codemirror/lang-json";
import {
  bracketMatching,
  defaultHighlightStyle,
  foldGutter,
  foldKeymap,
  syntaxHighlighting,
} from "@codemirror/language";
import { EditorState } from "@codemirror/state";
import {
  drawSelection,
  EditorView,
  highlightActiveLine,
  highlightSpecialChars,
  keymap,
} from "@codemirror/view";
import { buildConfigJson } from "./buildConfig";

const initialInput = `{
  "Meh-x": {
    "e": { "app": "Emacs" },
    "t": { "app": "Terminal" }
  }
}
`;

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

const inputContainer = getElement("rules", HTMLDivElement);
const outputContainer = getElement("output", HTMLDivElement);
const status = getElement("status", HTMLDivElement);
const transformButton = getElement("transform", HTMLButtonElement);
const formatButton = getElement("format", HTMLButtonElement);
const copyButton = getElement("copy", HTMLButtonElement);

const editorTheme = EditorView.theme({
  "&": {
    fontSize: "13px",
  },
  ".cm-scroller": {
    fontFamily: "'SFMono-Regular', 'Menlo', 'Consolas', monospace",
  },
  "&.cm-focused": {
    outline: "2px solid #7ba0ff",
  },
});

const lineWrapping = EditorView.lineWrapping;

const inputView = new EditorView({
  parent: inputContainer,
  state: EditorState.create({
    doc: initialInput,
    extensions: [
      highlightSpecialChars(),
      history(),
      foldGutter(),
      drawSelection(),
      EditorState.allowMultipleSelections.of(true),
      syntaxHighlighting(defaultHighlightStyle, { fallback: true }),
      bracketMatching(),
      closeBrackets(),
      highlightActiveLine(),
      keymap.of([
        ...closeBracketsKeymap,
        ...defaultKeymap,
        ...historyKeymap,
        ...foldKeymap,
      ]),
      json(),
      editorTheme,
      lineWrapping,
      EditorView.updateListener.of(() => {
        refreshFormatState();
      }),
    ],
  }),
});

const outputView = new EditorView({
  parent: outputContainer,
  state: EditorState.create({
    doc: "",
    extensions: [
      highlightSpecialChars(),
      foldGutter(),
      drawSelection(),
      syntaxHighlighting(defaultHighlightStyle, { fallback: true }),
      bracketMatching(),
      keymap.of([...defaultKeymap, ...foldKeymap]),
      json(),
      editorTheme,
      lineWrapping,
      EditorState.readOnly.of(true),
    ],
  }),
});

function setStatus(message: string, kind: "ok" | "error") {
  status.textContent = message;
  status.dataset.state = kind;
}

function getInputValue(): string {
  return inputView.state.doc.toString();
}

function setOutputValue(value: string) {
  outputView.dispatch({
    changes: { from: 0, to: outputView.state.doc.length, insert: value },
  });
}

function runTransform() {
  try {
    const configJson = buildConfigJson(getInputValue());
    setOutputValue(configJson);
    setStatus("Generated karabiner config.", "ok");
    refreshCopyState();
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    setOutputValue("");
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
  formatButton.disabled = !isValidJson(getInputValue());
}

function refreshCopyState() {
  copyButton.disabled = outputView.state.doc.length === 0;
}

function formatInput() {
  try {
    const parsed = JSON.parse(getInputValue());
    const formatted = `${JSON.stringify(parsed, null, 2)}\n`;
    inputView.dispatch({
      changes: { from: 0, to: inputView.state.doc.length, insert: formatted },
    });
    setStatus("Formatted input.", "ok");
    refreshFormatState();
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    setStatus(message, "error");
  }
}

async function copyOutput() {
  try {
    await navigator.clipboard.writeText(outputView.state.doc.toString());
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

inputView.dom.addEventListener("keydown", (event) => {
  if ((event.metaKey || event.ctrlKey) && event.key === "Enter") {
    event.preventDefault();
    runTransform();
  }
});

runTransform();
refreshFormatState();
