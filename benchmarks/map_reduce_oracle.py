"""Bounded byte reference for TheAlgorithms/Java MapReduce.countWordFrequencies."""

from __future__ import annotations

MAX_INPUT_LENGTH = 256
MAX_OUTPUT_BYTES = 1024
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY_RESULT = -2
I64_MIN, I64_MAX = -(1 << 63), (1 << 63) - 1
_ASCII_WHITESPACE = frozenset((9, 10, 11, 12, 13, 32))


def expected_output(values: list[int] | tuple[int, ...],
                    output_capacity: int | None = None) -> tuple[int, bytes]:
    """Return first-seen token counts as ASCII bytes, or an ABI status."""
    if (not isinstance(values, (list, tuple)) or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return INVALID_RESULT, b""
    if any(value not in _ASCII_WHITESPACE and not 32 <= value <= 126
           for value in values):
        return INVALID_RESULT, b""

    # Java String.trim() removes leading/trailing code points <= U+0020.
    start, end = 0, len(values)
    while start < end and values[start] <= 32:
        start += 1
    while end > start and values[end - 1] <= 32:
        end -= 1

    counts: dict[bytes, int] = {}
    order: list[bytes] = []
    if start == end:
        # Java's "".split("\\s+") returns one empty string.
        counts[b""] = 1
        order.append(b"")
    else:
        cursor = start
        while cursor < end:
            while cursor < end and values[cursor] in _ASCII_WHITESPACE:
                cursor += 1
            token_start = cursor
            while cursor < end and values[cursor] not in _ASCII_WHITESPACE:
                cursor += 1
            token = bytes(values[token_start:cursor])
            if token in counts:
                counts[token] += 1
            else:
                counts[token] = 1
                order.append(token)

    result = b",".join(token + b": " + str(counts[token]).encode("ascii")
                       for token in order)
    if output_capacity is not None:
        if type(output_capacity) is not int or output_capacity < 0:
            return INVALID_RESULT, b""
        if output_capacity < len(result):
            return INSUFFICIENT_CAPACITY_RESULT, b""
    return len(result), result
