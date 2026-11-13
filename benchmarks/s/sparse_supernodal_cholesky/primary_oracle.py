"""Right-looking supernodal numerical factorization for the bounded profile."""

from __future__ import annotations

import math
import struct
from collections.abc import Sequence

from .independent_oracle import (
    MAX_N, MAX_VALID_INPUT_LENGTH, MAX_PARSEABLE_INPUT_LENGTH, MAX_OUTPUT_BYTES,
    expected_output as validate_and_reference,
)

WORKSPACE_BYTES = 4096


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    # Validate the full frame and positive definiteness before output errors.
    status, _ = validate_and_reference(values, input_is_null=input_is_null,
                                       input_length=input_length)
    if status < 0:
        return -1, b""
    assert values is not None
    n, count = values[:2]
    boundaries = values[2:3 + count]
    masks = values[3 + count:3 + count + n]
    packed = values[3 + count + n:]
    work = [[0.0] * n for _ in range(n)]
    cursor = 0
    for row in range(n):
        for col in range(row + 1):
            work[row][col] = packed[cursor] / 1000.0
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
