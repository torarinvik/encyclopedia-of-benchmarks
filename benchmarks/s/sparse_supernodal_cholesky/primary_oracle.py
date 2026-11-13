"""Right-looking supernodal numerical factorization for the bounded profile."""

from __future__ import annotations

import math
import struct
from collections.abc import Sequence

MAX_N = 8
MAX_VALID_INPUT_LENGTH = 55
MAX_PARSEABLE_INPUT_LENGTH = 56
MAX_OUTPUT_BYTES = 288
WORKSPACE_BYTES = 4096


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length != len(values)
            or not 2 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)):
        return -1, b""
    n, count = values[:2]
    if not 1 <= n <= MAX_N or not 1 <= count <= n:
        return -1, b""
    if len(values) != 3 + count + n + n * (n + 1) // 2:
        return -1, b""
    boundaries = values[2:3 + count]
    masks = values[3 + count:3 + count + n]
    packed = values[3 + count + n:]
    if boundaries[0] != 0 or boundaries[-1] != n:
        return -1, b""
    for index in range(count):
        if not 0 <= boundaries[index] < boundaries[index + 1] <= n:
            return -1, b""
    for row, mask in enumerate(masks):
        if mask < 0 or mask >= 1 << (row + 1) or not mask & (1 << row):
            return -1, b""
    for col in range(n):
        for row in range(col + 1, n):
            if masks[row] & (1 << col):
                for target in range(row + 1, n):
                    if masks[target] & (1 << col) and not masks[target] & (1 << row):
                        return -1, b""
    for start, end in zip(boundaries, boundaries[1:]):
        for row in range(start, end):
            for col in range(start, row):
                if not masks[row] & (1 << col):
                    return -1, b""
        for row in range(end, n):
            present = sum(bool(masks[row] & (1 << col)) for col in range(start, end))
            if present not in (0, end - start):
                return -1, b""
    work = [[0.0] * n for _ in range(n)]
    cursor = 0
    for row in range(n):
        for col in range(row + 1):
            value = packed[cursor]
            if abs(value) > 1_000_000 or (not masks[row] & (1 << col) and value != 0):
                return -1, b""
            work[row][col] = value / 1000.0
            cursor += 1

    for start, end in zip(boundaries, boundaries[1:]):
        # Factor the supernode's diagonal block in place.
        for col in range(start, end):
            pivot = work[col][col]
            if not math.isfinite(pivot) or pivot <= 0:
                return -1, b""
            work[col][col] = math.sqrt(pivot)
            for row in range(col + 1, end):
                work[row][col] /= work[col][col]
            for row in range(col + 1, end):
                for target in range(col + 1, row + 1):
                    work[row][target] -= work[row][col] * work[target][col]

        panel = [row for row in range(end, n) if masks[row] & (1 << start)]
        for row in panel:
            for col in range(start, end):
                value = work[row][col]
                for k in range(start, col):
                    value -= work[row][k] * work[col][k]
                work[row][col] = value / work[col][col]
        for index, row in enumerate(panel):
            for target in panel[:index + 1]:
                update = sum(work[row][k] * work[target][k] for k in range(start, end))
                work[row][target] -= update

    required = 8 * n * (n + 1) // 2
    if output_is_null or (capacity is not None and (type(capacity) is not int or capacity < required)):
        return -2, b""
    output = b"".join(struct.pack("<d", work[row][col])
                      for row in range(n) for col in range(row + 1))
    return required, output
