"""Quadratic interval enumeration for hanging-line histogram fixtures."""

INVALID = -(1 << 63)
MAX_LENGTH = 64
MAX_HEIGHT = 1_000_000


def expected(values, length=None, input_is_null=False):
    if input_is_null or values is None:
        actual_length = 0 if length is None else length
        return 0 if actual_length == 0 else INVALID
    if length is not None and length != len(values):
        return INVALID
    if len(values) > MAX_LENGTH or any(not 0 <= height <= MAX_HEIGHT for height in values):
        return INVALID

    best = 0
    for left in range(len(values)):
        minimum = MAX_HEIGHT
        for right in range(left, len(values)):
            minimum = min(minimum, values[right])
            area = minimum * (right - left + 1)
            if area > best:
                best = area
    return best
