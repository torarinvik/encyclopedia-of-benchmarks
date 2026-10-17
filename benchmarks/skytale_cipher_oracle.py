"""Independent oracle for the bounded Skytale transposition contract."""

from __future__ import annotations

from collections.abc import Sequence

MAX_TEXT_LENGTH = 256
MAX_PARSEABLE_INPUT_LENGTH = 260
MAX_KEY = 256


def _encrypt(text: bytes, key: int) -> bytes:
    return bytes(text[position] for row in range(key)
                 for position in range(row, len(text), key))


def _decrypt(text: bytes, key: int) -> bytes:
    length = len(text)
    base, extra = divmod(length, key)
    rows: list[bytes] = []
    offset = 0
    for row in range(key):
        row_length = base + (1 if row < extra else 0)
        rows.append(text[offset:offset + row_length])
        offset += row_length
    positions = [0] * key
    output = bytearray()
    for index in range(length):
        row = index % key
        output.append(rows[row][positions[row]])
        positions[row] += 1
    return bytes(output)


def expected_output(values: Sequence[int], capacity: int | None = None,
                    output_is_null: bool = False,
                    input_is_null: bool = False) -> tuple[int, bytes]:
    """Return the expected byte-output result and exact bytes for packed input."""
    if type(input_is_null) is not bool or type(output_is_null) is not bool:
        return -1, b""
    if input_is_null:
        return -1, b""
    if (not isinstance(values, Sequence) or isinstance(values, (str, bytes, bytearray))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    mode, key, text_length = values[:3]
    if mode not in (0, 1) or not 1 <= key <= MAX_KEY:
        return -1, b""
    if not 0 <= text_length <= MAX_TEXT_LENGTH or len(values) != 3 + text_length:
        return -1, b""
    text = values[3:]
    if any(not 0 <= value <= 127 for value in text):
        return -1, b""
    raw = bytes(text)
    output = _encrypt(raw, key) if mode == 0 else _decrypt(raw, key)
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if output_is_null or (capacity is not None and capacity < len(output)):
        return -2, b""
    return len(output), output
