"""Independent per-type copy-count dynamic program for bounded knapsack."""

from __future__ import annotations

MAX_TYPES = 16
MAX_CAPACITY = 64
MAX_WEIGHT = 16
MAX_VALUE = 100
MAX_COUNT = 16
INVALID_RESULT = -1
MAX_VALID_INPUT_LENGTH = 50
MAX_PARSEABLE_INPUT_LENGTH = 51
MAX_WORKSPACE_BYTES = 1024


def expected_result(values, input_is_null=False, input_length=None):
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT
    if (len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return INVALID_RESULT
    n, capacity = values[:2]
    if not 0 <= n <= MAX_TYPES or not 0 <= capacity <= MAX_CAPACITY:
        return INVALID_RESULT
    if len(values) != 2 + 3 * n:
        return INVALID_RESULT

    best = [0] * (capacity + 1)
    for offset in range(2, len(values), 3):
        weight, value, count = values[offset:offset + 3]
        if not 1 <= weight <= MAX_WEIGHT or not 0 <= value <= MAX_VALUE or not 0 <= count <= MAX_COUNT:
            return INVALID_RESULT
        previous = best
        current = [0] * (capacity + 1)
        for limit in range(capacity + 1):
            maximum = previous[limit]
            copies = 1
            while copies <= count and copies * weight <= limit:
                candidate = previous[limit - copies * weight] + copies * value
                if candidate > maximum:
                    maximum = candidate
                copies += 1
            current[limit] = maximum
        best = current
    return best[capacity]
