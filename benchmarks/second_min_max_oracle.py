"""Independent oracle for Java's distinct second-minimum/second-maximum scan."""

from __future__ import annotations

from collections.abc import Sequence

INVALID_RESULT = -(2**63)
MIN_ARRAY_LENGTH = 2
MAX_ARRAY_LENGTH = 256
MAX_INPUT_LENGTH = MAX_ARRAY_LENGTH + 3  # includes one parseable over-limit count case
INT32_MIN = -(2**31)
INT32_MAX = 2**31 - 1


def expected_result(values: Sequence[int]) -> int:
    if (not isinstance(values, (list, tuple)) or not 4 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return INVALID_RESULT
    operation, raw_count = values[0], values[1]
    if operation not in (0, 1) or not MIN_ARRAY_LENGTH <= raw_count <= MAX_ARRAY_LENGTH:
        return INVALID_RESULT
    if len(values) != raw_count + 2:
        return INVALID_RESULT
    items = values[2:]
    if any(value < INT32_MIN or value > INT32_MAX for value in items):
        return INVALID_RESULT

    initial = INT32_MAX if operation == 0 else INT32_MIN
    best = initial
    second = initial
    for value in items:
        better = value < best if operation == 0 else value > best
        if better:
            second = best
            best = value
        else:
            improves_second = value < second if operation == 0 else value > second
            if improves_second and value != best:
                second = value

    # The Java methods throw when the sentinel remains unchanged, including
    # the two boundary cases where the real second value equals that sentinel.
    return INVALID_RESULT if second == initial else second
