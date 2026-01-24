export type KeyCodes = {
  regular: Set<string>;
  consumer: Set<string>;
  pointer: Set<string>;
};

export function parseKeyCodes(data: unknown): KeyCodes {
  if (!Array.isArray(data)) {
    throw new Error("key codes data must be an array");
  }

  const regular = new Set<string>();
  const consumer = new Set<string>();
  const pointer = new Set<string>();

  for (const entry of data) {
    const items = (entry as { data?: unknown }).data;
    if (!Array.isArray(items) || items.length !== 1) {
      continue;
    }

    const item = items[0] as {
      key_code?: unknown;
      consumer_key_code?: unknown;
      pointing_button?: unknown;
    };

    if (typeof item.key_code === "string") {
      regular.add(item.key_code);
    } else if (typeof item.consumer_key_code === "string") {
      consumer.add(item.consumer_key_code);
    } else if (typeof item.pointing_button === "string") {
      pointer.add(item.pointing_button);
    }
  }

  return { regular, consumer, pointer };
}
