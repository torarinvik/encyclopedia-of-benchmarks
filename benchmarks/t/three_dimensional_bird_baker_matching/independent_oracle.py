"""Independent direct-cell reference for 3D exact pattern occurrences."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_VALID_INPUT_LENGTH = 195
MAX_PARSEABLE_INPUT_LENGTH = 196
MAX_OUTPUT_BYTES = 3008


def _read(values: Sequence[int]):
    if len(values) < 7 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    r, c, d, pr, pc, pd = values[:6]
    if (not 1 <= r <= 5 or not 1 <= c <= 5 or not 1 <= d <= 5
            or not 1 <= pr <= 4 or not 1 <= pc <= 4 or not 1 <= pd <= 4
            or pr > r or pc > c or pd > d):
        return None
    text_size, pattern_size = r * c * d, pr * pc * pd
    if len(values) != 6 + text_size + pattern_size:
        return None
    text = tuple(values[6:6 + text_size])
    pattern = tuple(values[6 + text_size:])
    if any(value < 0 or value > 3 for value in text + pattern):
        return None
    return r, c, d, pr, pc, pd, text, pattern


def _matches(parsed) -> list[tuple[int, int, int]]:
    r, c, d, pr, pc, pd, text, pattern = parsed
    found = []
    for row in range(r - pr + 1):
        for column in range(c - pc + 1):
            for depth in range(d - pd + 1):
                equal = True
                for pattern_depth in range(pd):
                    for pattern_row in range(pr):
                        for pattern_column in range(pc):
                            text_index = ((depth + pattern_depth) * r + row + pattern_row) * c + column + pattern_column
                            pattern_index = (pattern_depth * pr + pattern_row) * pc + pattern_column
                            if text[text_index] != pattern[pattern_index]:
                                equal = False
                                break
                        if not equal:
                            break
                    if not equal:
                        break
                if equal:
                    found.append((row, column, depth))
    return found


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
