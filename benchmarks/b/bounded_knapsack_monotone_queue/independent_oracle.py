"""Direct multiplicity-enumeration oracle for bounded knapsack."""

from __future__ import annotations

MAX_CAPACITY = 64
MAX_TYPES = 16
MAX_WEIGHT = 16
MAX_VALUE = 100
MAX_COUNT = 16
MAX_VALID_INPUT_LENGTH = 2 + 3 * MAX_TYPES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
INVALID_RESULT = -1
I64_MIN = -(2**63)
I64_MAX = 2**63 - 1


def expected_result(values: list[int]) -> int:
    """Enumerate every allowed copy count for each type in a two-row DP."""
    if (not isinstance(values, list)
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return INVALID_RESULT
    capacity, type_count = values[0], values[1]
    if capacity < 0 or capacity > MAX_CAPACITY or type_count < 0 or type_count > MAX_TYPES:
        return INVALID_RESULT
    if len(values) != 2 + 3 * type_count:
        return INVALID_RESULT

    best = [0] * (capacity + 1)
    for item in range(type_count):
        weight, value, multiplicity = values[2 + 3 * item:5 + 3 * item]
        if (weight < 1 or weight > MAX_WEIGHT or value < 0 or value > MAX_VALUE
                or multiplicity < 0 or multiplicity > MAX_COUNT):
            return INVALID_RESULT
        updated = best.copy()
        for available_capacity in range(capacity + 1):
            copies = 1
            while copies <= multiplicity and copies * weight <= available_capacity:
                candidate = best[available_capacity - copies * weight] + copies * value
                if candidate > updated[available_capacity]:
                    updated[available_capacity] = candidate
                copies += 1
        best = updated
    return best[capacity]
