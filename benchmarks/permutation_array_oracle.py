"""Independent oracle for Java's duplicate-preserving array permutations."""

from __future__ import annotations

import math
import struct
from collections.abc import Sequence

MAX_LENGTH = 6
MIN_VALUE = -(2**31)
MAX_VALUE = 2**31 - 1
MAX_VALID_INPUT_LENGTH = MAX_LENGTH + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = math.factorial(MAX_LENGTH) * MAX_LENGTH * 4


def expected_output(
    values: Sequence[int],
    output_capacity: int = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    if (
        not isinstance(values, (tuple, list))
        or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)
    ):
        return -1, b""

    n = values[0]
    items = list(values[1:])
    if not 0 <= n <= MAX_LENGTH or len(items) != n:
        return -1, b""
    if any(not MIN_VALUE <= value <= MAX_VALUE for value in items):
        return -1, b""

    rows: list[tuple[int, ...]] = []

    def backtracking(index: int) -> None:
        if index == n:
            rows.append(tuple(items))
        for position in range(index, n):
            items[index], items[position] = items[position], items[index]
            backtracking(index + 1)
            items[index], items[position] = items[position], items[index]

    backtracking(0)
    output = b"".join(struct.pack("<i", value) for row in rows for value in row)

    if type(output_is_null) is not bool:
        return -1, b""
    if type(output_capacity) is not int:
        return -1, b""
    if (output_is_null and output) or output_capacity < len(output):
        return -2, b""
    return len(rows), output
