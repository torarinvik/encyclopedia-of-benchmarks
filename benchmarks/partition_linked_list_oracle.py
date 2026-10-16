"""Stable array model for the pinned linked-list partition routine."""
MAX_COUNT = 64
MAX_INPUT_LENGTH = MAX_COUNT + 2
MIN_I32 = -(1 << 31)
MAX_I32 = (1 << 31) - 1
MODULUS = 1_000_000_007
BASE = 2_000_000_003
INVALID_RESULT = -1

def expected_result(values: list[int]) -> int:
    if (not isinstance(values, list) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(x) is not int for x in values)):
        return INVALID_RESULT
    count, pivot = values[:2]
    if (not 0 <= count <= MAX_COUNT or len(values) != count + 2
            or not MIN_I32 <= pivot <= MAX_I32):
        return INVALID_RESULT
    items = values[2:]
    if any(not MIN_I32 <= x <= MAX_I32 for x in items):
        return INVALID_RESULT
    reordered = [x for x in items if x < pivot] + [x for x in items if x >= pivot]
    result = 0
    for value in reordered:
        result = (result * BASE + value - MIN_I32) % MODULUS
    return result
