"""Per-type copy-count DP, independent of the primary update directions."""

from __future__ import annotations

MAX_TYPES = 16
MAX_CAPACITY = 64
MAX_WEIGHT = 16
MAX_VALUE = 100
MAX_BOUNDED_COUNT = 16
INVALID_RESULT = -1
MAX_VALID_INPUT_LENGTH = 66
MAX_PARSEABLE_INPUT_LENGTH = 67
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
    if len(values) != 2 + 4 * n:
        return INVALID_RESULT

    best = [0] * (capacity + 1)
    for offset in range(2, len(values), 4):
        mode, weight, value, limit = values[offset:offset + 4]
        if mode not in (0, 1, 2) or not 1 <= weight <= MAX_WEIGHT or not 0 <= value <= MAX_VALUE:
            return INVALID_RESULT
        if mode == 0 and limit != 1:
            return INVALID_RESULT
        if mode == 1 and limit != 0:
            return INVALID_RESULT
        if mode == 2 and not 0 <= limit <= MAX_BOUNDED_COUNT:
            return INVALID_RESULT

        if mode == 0:
            max_copies = 1
        elif mode == 1:
            max_copies = capacity // weight
        else:
            max_copies = limit
        previous = best
        current = [0] * (capacity + 1)
        for available in range(capacity + 1):
            maximum = previous[available]
            copies = 1
            while copies <= max_copies and copies * weight <= available:
                candidate = previous[available - copies * weight] + copies * value
                if candidate > maximum:
                    maximum = candidate
                copies += 1
            current[available] = maximum
        best = current
    return best[capacity]
