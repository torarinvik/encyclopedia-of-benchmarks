"""Oracle for Dart/Python's shared positional Heap permutation order."""

from __future__ import annotations

import math
import struct

I64_MIN = -(2**63)
I64_MAX = 2**63 - 1
MIN_PERMUTATION_LENGTH = 1
MAX_PERMUTATION_LENGTH = 6
MAX_INPUT_LENGTH = MAX_PERMUTATION_LENGTH + 1
BYTES_PER_VALUE = 8
MAX_OUTPUT_BYTES = math.factorial(MAX_PERMUTATION_LENGTH) * MAX_PERMUTATION_LENGTH * BYTES_PER_VALUE


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    """Return the number of emitted rows and their flattened i64-LE bytes."""
    if (not isinstance(values, (list, tuple))
            or not MIN_PERMUTATION_LENGTH <= len(values) <= MAX_PERMUTATION_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1, b""

    items = list(values)
    output = bytearray()
    n = len(items)

    def emit() -> None:
        for value in items:
            output.extend(struct.pack("<q", value))

    def generate(k: int) -> None:
        if k == 1:
            emit()
            return
        generate(k - 1)
        for index in range(k - 1):
            swap_index = index if k % 2 == 0 else 0
            items[swap_index], items[k - 1] = items[k - 1], items[swap_index]
            generate(k - 1)

    generate(n)
    return math.factorial(n), bytes(output)
