"""Oracle for the bounded sorted ASCII permutation-list hash."""
from itertools import permutations

MAX_INPUT_LENGTH = 8
MAX_TEXT_LENGTH = 7
INVALID_RESULT = -1


def _hash_permutations(rows: list[bytes]) -> int:
    value = 2166136261
    for row in rows:
        for byte in row + b"\0":
            value = ((value ^ byte) * 16777619) & 0xFFFFFFFF
    return value


def expected_result(values: list[int]) -> int:
    if (not isinstance(values, list) or len(values) < 2 or len(values) > MAX_INPUT_LENGTH
            or any(type(x) is not int or x < 0 or x > 127 for x in values)):
        return INVALID_RESULT
    length = values[0]
    if not 1 <= length <= MAX_TEXT_LENGTH or len(values) != length + 1:
        return INVALID_RESULT
    chars = values[1:]
    if any(not 33 <= x <= 126 for x in chars) or len(set(chars)) != length:
        return INVALID_RESULT
    rows = sorted(bytes(row) for row in permutations(chars))
    return _hash_permutations(rows)
