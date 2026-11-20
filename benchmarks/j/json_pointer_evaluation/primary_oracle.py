"""Bounded flat-tree JSON Pointer reference using node-table scans."""

from __future__ import annotations

MAX_NODES = 32
MAX_POINTER_LENGTH = 64
MAX_KEY_LENGTH = 16
RECORD_WORDS = 21
MAX_VALID_INPUT_LENGTH = 3 + MAX_POINTER_LENGTH + MAX_NODES * RECORD_WORDS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
WORKSPACE_BYTES = MAX_POINTER_LENGTH * 8
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


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
    length = len(data) if input_length is None else input_length
    if length != len(data) or length < 3:
        return -1
    n, root, pointer_length = data[:3]
    if not 1 <= n <= MAX_NODES or not 0 <= root < n:
        return -1
    if not 0 <= pointer_length <= MAX_POINTER_LENGTH:
        return -1
    base = 3 + pointer_length
    if length != base + n * RECORD_WORDS:
        return -1
    pointer = data[3:base]
    if any(not 0 <= ch <= 127 for ch in pointer):
        return -1
    if pointer and pointer[0] != ord("/"):
        return -1

    rows: list[tuple[int, int, bytes, int, int]] = []
    for node in range(n):
        start = base + node * RECORD_WORDS
        row = data[start : start + RECORD_WORDS]
        kind, parent, key_length = row[:3]
        key_fields = row[3:19]
        array_index, scalar_payload = row[19:21]
        if kind not in (0, 1, 2) or not 0 <= key_length <= MAX_KEY_LENGTH:
            return -1
        if any(not 0 <= ch <= 127 for ch in key_fields[:key_length]):
            return -1
        if any(ch != 0 for ch in key_fields[key_length:]):
            return -1
        if node == root:
            if parent != -1 or key_length != 0 or array_index != -1:
                return -1
        elif not 0 <= parent < n or parent == node:
            return -1
        rows.append((kind, parent, bytes(key_fields[:key_length]), array_index, scalar_payload))

    for node, (kind, parent, _key, array_index, _payload) in enumerate(rows):
        if node == root:
            continue
        parent_kind = rows[parent][0]
        if parent_kind not in (0, 1):
            return -1
        if parent_kind == 0:
            if array_index != -1:
                return -1
        elif data[base + node * RECORD_WORDS + 2] != 0 or array_index < 0:
            return -1

    for node in range(n):
        cursor = node
        for _ in range(n):
            if cursor == root:
                break
            cursor = rows[cursor][1]
            if not 0 <= cursor < n:
                return -1
        if cursor != root:
            return -1

    for parent, (kind, *_rest) in enumerate(rows):
        if kind != 1:
            continue
        indices = [row[3] for row in rows if row[1] == parent]
        if sorted(indices) != list(range(len(indices))):
            return -1

    if not pointer:
        return root
    tokens: list[bytes] = []
    token = bytearray()
    pos = 1
    while pos <= pointer_length:
        if pos == pointer_length or pointer[pos] == ord("/"):
            tokens.append(bytes(token))
            token.clear()
            pos += 1
            continue
        ch = pointer[pos]
        if ch == ord("~"):
            pos += 1
            if pos >= pointer_length:
                return -1
            escaped = pointer[pos]
            if escaped == ord("0"):
                ch = ord("~")
            elif escaped == ord("1"):
                ch = ord("/")
            else:
                return -1
        token.append(ch)
        pos += 1

    current = root
    for part in tokens:
        kind = rows[current][0]
        if kind == 0:
            matches = [node for node, row in enumerate(rows)
                       if row[1] == current and row[2] == part]
        elif kind == 1:
            if not part or (len(part) > 1 and part[0] == ord("0")):
                return -2
            if any(ch < ord("0") or ch > ord("9") for ch in part):
                return -2
            index = int(part)
            matches = [node for node, row in enumerate(rows)
                       if row[1] == current and row[3] == index]
        else:
            return -2
        if len(matches) != 1:
            return -2
        current = matches[0]
    return current
