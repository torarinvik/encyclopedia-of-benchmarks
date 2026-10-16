"""Independent frequency-map oracle for Ruby's hash-table good-pairs variant."""

from __future__ import annotations

I64_MIN = -(2**63)
I64_MAX = 2**63 - 1
MAX_ARRAY_LENGTH = 256
MAX_INPUT_LENGTH = 258
MAX_VALUE = 1_000_000


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or not values
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1
    declared = values[0]
    if not 0 <= declared <= MAX_ARRAY_LENGTH or len(values) != declared + 1:
        return -1
    data = values[1:]
    if any(value < -MAX_VALUE or value > MAX_VALUE for value in data):
        return -1
    frequencies: dict[int, int] = {}
    for value in data:
        frequencies[value] = frequencies.get(value, 0) + 1
    return sum(count * (count - 1) // 2 for count in frequencies.values())
