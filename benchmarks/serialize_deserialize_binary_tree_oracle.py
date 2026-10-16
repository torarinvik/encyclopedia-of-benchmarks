"""Independent oracle for canonical preorder binary-tree round trips."""

from __future__ import annotations

MAX_INPUT_LENGTH = 2200
MAX_NODES = 127
MAX_OUTPUT_LENGTH = 2163
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY = -2


def expected_output(values: tuple[int, ...] | list[int],
                    capacity: int | None = None) -> tuple[int, bytes]:
    """Validate a preorder tree token stream and return its canonical encoding."""
    if (not isinstance(values, (tuple, list)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not 0 <= value <= 127 for value in values)):
        return INVALID_RESULT, b""

    tokens = bytes(values).split(b",")
    slots = 1
    node_count = 0
    canonical: list[bytes] = []
    whitespace = b"\t\n\v\f\r "
    for token in tokens:
        if slots == 0:
            return INVALID_RESULT, b""
        slots -= 1
        if token == b"null":
            canonical.append(token)
            continue

        token = token.strip(whitespace)
        if not token:
            return INVALID_RESULT, b""
        negative = token.startswith(b"-")
        digits = token[1:] if token[:1] in (b"+", b"-") else token
        if not digits or any(not 48 <= byte <= 57 for byte in digits):
            return INVALID_RESULT, b""
        number = 0
        limit = 2**31 if negative else 2**31 - 1
        for byte in digits:
            digit = byte - 48
            if number > (limit - digit) // 10:
                return INVALID_RESULT, b""
            number = number * 10 + digit
        number = -number if negative else number
        node_count += 1
        if node_count > MAX_NODES:
            return INVALID_RESULT, b""
        canonical.append(str(number).encode("ascii"))
        slots += 2

    if slots != 0:
        return INVALID_RESULT, b""
    output = b",".join(canonical)
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    if capacity is not None and len(output) > capacity:
        return INSUFFICIENT_CAPACITY, b""
    return len(output), output
