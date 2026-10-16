"""Oracle for the pinned Java stable move-#-to-end transformation."""

from __future__ import annotations

MAX_TEXT_LENGTH = 256
MAX_PARSEABLE_INPUT_LENGTH = MAX_TEXT_LENGTH + 2


def expected_output(values: list[int], capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, list) or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)):
        return -1, b""
    length = values[0]
    if not 0 <= length <= MAX_TEXT_LENGTH or len(values) != length + 1:
        return -1, b""
    source = values[1:]
    if any(not 0 <= byte <= 127 for byte in source):
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if capacity is not None and capacity < length:
        return -2, b""
    output = [byte for byte in source if byte != 35]
    output.extend([35] * (length - len(output)))
    return length, bytes(output)
