"""Independent byte oracle for the pinned Route/columnar transposition cipher."""

from __future__ import annotations

MAX_TEXT_LENGTH = 256
MAX_OUTPUT_BYTES = 256
MAX_INPUT_LENGTH = 3 + MAX_TEXT_LENGTH


def _encrypt(key: int, message: bytes) -> bytes:
    return bytes(message[index] for column in range(key) for index in range(column, len(message), key))


def _decrypt(key: int, message: bytes) -> bytes:
    columns = (len(message) + key - 1) // key
    shaded = columns * key - len(message)
    final_column_rows = key - shaded
    lengths = [key] * columns
    lengths[-1] = final_column_rows
    offsets: list[int] = []
    total = 0
    for count in lengths:
        offsets.append(total)
        total += count
    result = bytearray(len(message))
    seen = [0] * columns
    row = 0
    column = 0
    for value in message:
        result[offsets[column] + seen[column]] = value
        seen[column] += 1
        column += 1
        if column == columns or (column == columns - 1 and row >= final_column_rows):
            column = 0
            row += 1
    return bytes(result)


def expected_output(
    values: list[int] | tuple[int, ...] | None,
    capacity: int | None = None,
) -> tuple[int, bytes]:
    """Return `(byte count, output)` for `[mode, key, n, ASCII bytes...]`.

    Modes are 0 for encryption and 1 for decryption. A valid but null or short
    output buffer is represented by passing a negative capacity.
    """
    if values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if (not 3 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    mode, key, count = values[:3]
    if mode not in (0, 1) or not 3 <= count <= MAX_TEXT_LENGTH or len(values) != 3 + count:
        return -1, b""
    if not 2 <= key < count:
        return -1, b""
    payload = values[3:]
    if any(not 0 <= value <= 0x7F for value in payload):
        return -1, b""
    message = bytes(payload)
    result = _encrypt(key, message) if mode == 0 else _decrypt(key, message)
    if capacity is not None and capacity < len(result):
        return -2, b""
    return len(result), result
