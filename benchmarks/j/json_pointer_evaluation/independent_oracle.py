"""Independent tree-building and token-splitting JSON Pointer reference."""

from __future__ import annotations

from .primary_oracle import (
    I64_MAX,
    I64_MIN,
    MAX_NODES,
    MAX_POINTER_LENGTH,
    RECORD_WORDS,
)


def expected_result(values: list[int] | tuple[int, ...] | None,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)
            or input_length is not None and (
                type(input_length) is not int or input_length != len(values))):
        return -1
    data = list(values)
    actual_length = len(data) if input_length is None else input_length
    if actual_length != len(data) or actual_length < 3:
        return -1
    n, root, pointer_length = data[0], data[1], data[2]
    if not 1 <= n <= MAX_NODES or not 0 <= root < n:
        return -1
    if not 0 <= pointer_length <= MAX_POINTER_LENGTH:
        return -1
    table_start = 3 + pointer_length
    if actual_length != table_start + RECORD_WORDS * n:
        return -1
    pointer_codes = data[3:table_start]
    if any(not 0 <= code <= 127 for code in pointer_codes):
        return -1
    if pointer_codes and pointer_codes[0] != 47:
        return -1

    kinds: list[int] = []
    parents: list[int] = []
    keys: list[str] = []
    indexes: list[int] = []
    for node in range(n):
        offset = table_start + RECORD_WORDS * node
        kind, parent, key_length = data[offset : offset + 3]
        key_codes = data[offset + 3 : offset + 19]
        array_index = data[offset + 19]
        if kind not in (0, 1, 2) or not 0 <= key_length <= 16:
            return -1
        if any(not 0 <= code <= 127 for code in key_codes[:key_length]):
            return -1
        if any(code != 0 for code in key_codes[key_length:]):
            return -1
        if node == root:
            if parent != -1 or key_length != 0 or array_index != -1:
                return -1
        elif not 0 <= parent < n or parent == node:
            return -1
        kinds.append(kind)
        parents.append(parent)
        keys.append(bytes(key_codes[:key_length]).decode("ascii"))
        indexes.append(array_index)

    for node in range(n):
        if node == root:
            continue
        parent = parents[node]
        if kinds[parent] == 0:
            if indexes[node] != -1:
                return -1
        elif kinds[parent] == 1:
            if keys[node] or indexes[node] < 0:
                return -1
        else:
            return -1
    for node in range(n):
        ancestor = node
        seen = 0
        while ancestor != root and seen < n:
            ancestor = parents[ancestor]
            if not 0 <= ancestor < n:
                return -1
            seen += 1
        if ancestor != root:
            return -1
    for parent in range(n):
        if kinds[parent] == 1:
            found = sorted(indexes[node] for node in range(n) if parents[node] == parent)
            if found != list(range(len(found))):
                return -1

    if pointer_codes:
        pointer = bytes(pointer_codes).decode("ascii")
        raw_tokens = pointer[1:].split("/")
        tokens = [raw.replace("~1", "/").replace("~0", "~") for raw in raw_tokens]
        # RFC 6901 disallows every other tilde escape. Check before replacement.
        for raw in raw_tokens:
            i = 0
            while i < len(raw):
                if raw[i] == "~":
                    if i + 1 == len(raw) or raw[i + 1] not in "01":
                        return -1
                    i += 2
                else:
                    i += 1
    else:
        tokens = []

    children: dict[int, list[int]] = {}
    for node, parent in enumerate(parents):
        if node != root:
            children.setdefault(parent, []).append(node)
    current = root
    for token in tokens:
        if kinds[current] == 0:
            matches = [node for node in children.get(current, ()) if keys[node] == token]
        elif kinds[current] == 1:
            if not token or (len(token) > 1 and token[0] == "0") or not token.isascii() or not token.isdigit():
                return -2
            matches = [node for node in children.get(current, ()) if indexes[node] == int(token)]
        else:
            return -2
        if len(matches) != 1:
            return -2
        current = matches[0]
    return current
