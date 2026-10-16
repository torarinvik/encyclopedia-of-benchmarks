"""Frequency-map oracle for the ordered pair of non-repeating elements."""

from __future__ import annotations

MAX_INPUT_LENGTH = 64
MAX_VALUE = (1 << 30) - 1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or len(values) % 2 != 0
            or any(type(value) is not int or not 0 <= value <= MAX_VALUE for value in values)):
        return -1

    frequencies: dict[int, int] = {}
    for value in values:
        frequencies[value] = frequencies.get(value, 0) + 1
    singles = [value for value, count in frequencies.items() if count == 1]
    if len(singles) != 2 or any(count not in (1, 2) for count in frequencies.values()):
        return -1

    lowest_set_bit = (singles[0] ^ singles[1]) & -(singles[0] ^ singles[1])
    if singles[0] & lowest_set_bit:
        first, second = singles
    else:
        first, second = singles[1], singles[0]
    return (first << 32) | second
