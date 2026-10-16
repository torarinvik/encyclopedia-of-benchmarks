"""Oracle for bounded consecutive-value run packing."""

MAX_COUNT = 64
MAX_INPUT_LENGTH = MAX_COUNT + 1
INVALID_RESULT = -1


def _mix(h: int, byte: int) -> int:
    return ((h ^ byte) * 16777619) & 0xFFFFFFFF


def _feed(h: int, value: int) -> int:
    bits = value & 0xFFFFFFFF
    for shift in (0, 8, 16, 24):
        h = _mix(h, (bits >> shift) & 0xFF)
    return h


def expected_result(values):
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(x) is not int for x in values)):
        return INVALID_RESULT
    count, items = values[0], values[1:]
    if not 0 <= count <= MAX_COUNT or len(items) != count:
        return INVALID_RESULT
    if any(not -(1 << 31) <= x < (1 << 31) for x in items):
        return INVALID_RESULT
    h = 2166136261
    i = 0
    while i < count:
        value = items[i]
        j = i + 1
        while j < count and items[j] == value:
            j += 1
        h = _feed(h, value)
        h = _feed(h, j - i)
        i = j
    return h
