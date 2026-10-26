"""Exact oracle for fixed-rational-scale geometric 2D matching."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT = 186
MAX_OUTPUT = 2312


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if len(values) < 6 or len(values) > MAX_INPUT or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return -1, b""
    h, w, ph, pw, p, q = values[:6]
    if not 1 <= h <= 12 or not 1 <= w <= 12 or not 1 <= ph <= 6 or not 1 <= pw <= 6 or not 1 <= q <= 8 or not q <= p <= 2 * q:
        return -1, b""
    if len(values) != 6 + h * w + ph * pw:
        return -1, b""
    text = [values[6 + r * w:6 + (r + 1) * w] for r in range(h)]
    pattern_offset = 6 + h * w
    pattern = [values[pattern_offset + r * pw:pattern_offset + (r + 1) * pw] for r in range(ph)]
    if any(not 0 <= x <= 255 for row in text + pattern for x in row):
        return -1, b""

    projected_rows = [((2 * y + 1) * q // (2 * p)) for y in range(h) if (2 * y + 1) * q < 2 * p * ph]
    projected_cols = [((2 * x + 1) * q // (2 * p)) for x in range(w) if (2 * x + 1) * q < 2 * p * pw]
    matches: list[tuple[int, int]] = []
    for top in range(h):
        if p * ph > q * (h - top):
            continue
        for left in range(w):
            if p * pw > q * (w - left):
                continue
            if all(text[top + iy][left + ix] == pattern[py][px]
                   for iy, py in enumerate(projected_rows)
                   for ix, px in enumerate(projected_cols)):
                matches.append((top, left))
    fields = [len(matches), *(coordinate for match in matches for coordinate in match)]
    payload = b"".join(struct.pack("<q", field) for field in fields)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
