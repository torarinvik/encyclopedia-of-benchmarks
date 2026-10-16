"""Oracle for the pinned Go Heap permutation generator's row order."""

from __future__ import annotations

import math

MAX_N = 7
MAX_INPUT_LENGTH = 2
MAX_OUTPUT_BYTES = math.factorial(MAX_N) * MAX_N


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    """Return row count and concatenated ASCII rows generated from n."""
    if (not isinstance(values, (list, tuple)) or len(values) != 1
            or type(values[0]) is not int or not 0 <= values[0] <= MAX_N):
        return -1, b""
    n = values[0]
    if n == 0:
        return 0, b""

    items = [ord("1") + index for index in range(n)]
    output = bytearray()
    rows = 0

    def emit() -> None:
        nonlocal rows
        output.extend(items)
        rows += 1

    def generate(size: int) -> None:
        if size == 1:
            emit()
            return
        for index in range(size):
            generate(size - 1)
            swap_index = index if size % 2 == 1 else 0
            items[swap_index], items[size - 1] = items[size - 1], items[swap_index]

    generate(n)
    return rows, bytes(output)
