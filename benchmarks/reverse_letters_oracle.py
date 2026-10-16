"""Independent oracle for the bounded reverse_letters contract."""
from __future__ import annotations

MAX_TEXT_LENGTH = 256
MAX_INPUT_LENGTH = MAX_TEXT_LENGTH + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MIN_PRINTABLE = 33
MAX_PRINTABLE = 126
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(values: list[int], capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, list) or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1, b""
    length = values[0]
    if not 0 <= length <= MAX_TEXT_LENGTH or len(values) != length + 1:
        return -1, b""
    text = values[1:]
    if any(value != 32 and not MIN_PRINTABLE <= value <= MAX_PRINTABLE for value in text):
        return -1, b""
    if text and (text[0] == 32 or text[-1] == 32 or any(a == b == 32 for a, b in zip(text, text[1:]))):
        return -1, b""
    words = bytes(text).split(b" ") if text else []
    output = b" ".join(word[::-1] for word in words) + b"\0"
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if capacity is not None and capacity < len(output):
        return -2, b""
    return len(output) - 1, output
