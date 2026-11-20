"""Direct full-cell reference for exact 2D pattern occurrences."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_VALID_INPUT_LENGTH = 290
MAX_PARSEABLE_INPUT_LENGTH = 291
MAX_OUTPUT_BYTES = 2312


def _read(values: Sequence[int]):
    if len(values) < 3 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    n, m = values[:2]
    if not 1 <= m <= n <= 12 or len(values) != 2 + n * n + m * m:
        return None
    text = tuple(values[2:2 + n * n])
    pattern = tuple(values[2 + n * n:])
    if any(value < 0 or value > 3 for value in text + pattern):
        return None
    return n, m, text, pattern


def _matches(parsed) -> list[tuple[int, int]]:
    n, m, text, pattern = parsed
    matches = []
    for row in range(n - m + 1):
        for column in range(n - m + 1):
            if all(text[(row + dr) * n + column + dc] == pattern[dr * m + dc]
                   for dr in range(m) for dc in range(m)):
                matches.append((row, column))
    return matches


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or input_length < 0)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and not isinstance(values, (list, tuple))
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    parsed = _read(values)
    if parsed is None:
        return -1, b""
    matches = _matches(parsed)
    words = [len(matches), *(coordinate for match in matches for coordinate in match)]
    payload = b"".join(struct.pack("<q", word) for word in words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload


def expected_result(values: Sequence[int] | None) -> int:
    return expected_output(values)[0]
