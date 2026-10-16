"""Independent oracle for the bounded multi-mode string switch-case source."""

from __future__ import annotations

import re

MAX_TEXT_LENGTH = 1024
MAX_INPUT_LENGTH = MAX_TEXT_LENGTH + 3
MAX_OUTPUT_LENGTH = MAX_TEXT_LENGTH
CAMEL_EMPTY = b"not valid string"


def expected_output(values: list[int], capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, list) or len(values) < 3 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    mode, separator, text_length = values[:3]
    text_values = values[3:]
    if (mode not in range(9) or not 0 <= separator <= 127
            or not 0 <= text_length <= MAX_TEXT_LENGTH or len(text_values) != text_length
            or any(not 0 <= value <= 127 for value in text_values)):
        return -1, b""
    if mode not in (3, 4) and separator != 0:
        return -1, b""

    text = bytes(text_values).decode("ascii")
    groups = [segment.split() for segment in re.split(r"[^ a-z A-Z 0-9 \s]", text)]
    if mode in (0, 1, 2):
        converted = "".join(word.capitalize() for group in groups for word in group)
        if mode == 2:
            converted = converted[:1].lower() + converted[1:] if converted else CAMEL_EMPTY.decode("ascii")
    else:
        upper = mode in (4, 6, 8)
        delim = chr(separator) if mode in (3, 4) else "_" if mode in (5, 6) else "-"
        convert = str.upper if upper else str.lower
        converted = "".join(delim.join(convert(word) for word in group) for group in groups)

    output = converted.encode("ascii")
    if len(output) > MAX_OUTPUT_LENGTH:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if capacity is not None and len(output) > capacity:
        return -2, b""
    return len(output), output
