from collections.abc import Sequence

MAX_INPUT_LENGTH = 3
INVALID_RESULT = -1
MAX_UINT53 = (1 << 53) - 1


def expected_result(values: Sequence[int]) -> int:
    if not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return INVALID_RESULT

    number = values[0]
    if not 0 <= number <= MAX_UINT53:
        return INVALID_RESULT

    first = values[1] if len(values) >= 2 else 1
    last = values[2] if len(values) >= 3 else 53
    if not 1 <= first <= 53 or not 1 <= last <= 53:
        return INVALID_RESULT

    return (number % (1 << last)) >> (first - 1)
