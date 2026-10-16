"""Oracle for the bounded pinned AArch64 permutation sort."""

from __future__ import annotations

MAX_LENGTH = 8
MAX_PARSEABLE_INPUT_LENGTH = MAX_LENGTH + 1
INVALID_RESULT = -1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Return the count of Heap-order candidates checked through the first sort."""
    if (not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63
                   for value in values)):
        return INVALID_RESULT

    working = list(values)
    if all(working[index - 1] <= working[index] for index in range(1, len(working))):
        return 1

    counters = [0] * len(working)
    checked = 1  # The assembly checks the original table before generating a permutation.
    index = 0
    while index < len(working):
        if counters[index] < index:
            swap_index = 0 if index % 2 == 0 else counters[index]
            working[swap_index], working[index] = working[index], working[swap_index]
            counters[index] += 1
            checked += 1
            if all(working[position - 1] <= working[position]
                   for position in range(1, len(working))):
                return checked
            index = 0
        else:
            counters[index] = 0
            index += 1
    return INVALID_RESULT
