"""Contract oracle for lower-midpoint BST construction from sorted values."""

from __future__ import annotations

MAX_INPUT_LENGTH = 16  # permits a 16-value malformed over-limit case
MAX_VALUES = 15
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1


def expected_result(values: list[int]) -> int:
    """Encode occupied heap indexes in the constructed balanced BST shape."""
    if (not isinstance(values, list) or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1
    if len(values) > MAX_VALUES or any(not I32_MIN <= value <= I32_MAX for value in values):
        return -1
    if any(values[index - 1] >= values[index] for index in range(1, len(values))):
        return -1

    shape = 0

    def build(start: int, end: int, heap_index: int) -> None:
        nonlocal shape
        if start >= end:
            return
        middle = start + (end - start - 1) // 2
        shape |= 1 << heap_index
        build(start, middle, 2 * heap_index + 1)
        build(middle + 1, end, 2 * heap_index + 2)

    build(0, len(values), 0)
    return shape
