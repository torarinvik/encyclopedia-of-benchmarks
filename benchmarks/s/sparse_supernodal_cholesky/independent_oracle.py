"""Dense reference for the bounded sparse-supernodal Cholesky contract."""

from __future__ import annotations

import math
import struct
from collections.abc import Sequence

MAX_N = 8
MAX_VALID_INPUT_LENGTH = 55
MAX_PARSEABLE_INPUT_LENGTH = 56
MAX_OUTPUT_BYTES = 288


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length != len(values)
            or not 2 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values)):
        return -1, b""
    n, supernodes = values[:2]
    if not 1 <= n <= MAX_N or not 1 <= supernodes <= n:
        return -1, b""
    triangle = n * (n + 1) // 2
    if len(values) != 2 + supernodes + 1 + n + triangle:
        return -1, b""
    boundaries = values[2:3 + supernodes]
    if (boundaries[0] != 0 or boundaries[-1] != n
            or any(a >= b for a, b in zip(boundaries, boundaries[1:]))):
        return -1, b""
    masks = values[3 + supernodes:3 + supernodes + n]
    for i, mask in enumerate(masks):
        if mask < 0 or mask >= 1 << (i + 1) or not mask & (1 << i):
            return -1, b""
    for col in range(n):
        rows = [row for row in range(col + 1, n) if masks[row] & (1 << col)]
        for i, row in enumerate(rows):
            for lower in rows[i + 1:]:
                if not masks[lower] & (1 << row):
                    return -1, b""
    for start, end in zip(boundaries, boundaries[1:]):
        for row in range(start, end):
            if any(not masks[row] & (1 << col) for col in range(start, row)):
                return -1, b""
        block_mask = ((1 << end) - 1) ^ ((1 << start) - 1)
        for row in range(end, n):
            if masks[row] & block_mask not in (0, block_mask):
                return -1, b""
    packed = values[3 + supernodes + n:]
    matrix = [[0.0] * n for _ in range(n)]
    cursor = 0
    for row in range(n):
        for col in range(row + 1):
            value = packed[cursor]
            cursor += 1
            if abs(value) > 1_000_000 or (not masks[row] & (1 << col) and value != 0):
                return -1, b""
            matrix[row][col] = value / 1000.0
    factor = [[0.0] * n for _ in range(n)]
    for row in range(n):
        for col in range(row + 1):
            if not masks[row] & (1 << col):
                continue
            value = matrix[row][col] - sum(factor[row][k] * factor[col][k] for k in range(col))
            if row == col:
                if not math.isfinite(value) or value <= 0:
                    return -1, b""
                factor[row][col] = math.sqrt(value)
            else:
                factor[row][col] = value / factor[col][col]
    required = 8 * triangle
    if output_is_null or (capacity is not None and (type(capacity) is not int or capacity < required)):
        return -2, b""
    payload = b"".join(struct.pack("<d", factor[i][j]) for i in range(n) for j in range(i + 1))
    return required, payload
