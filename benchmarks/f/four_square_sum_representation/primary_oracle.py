"""Bounded lexicographic four-square decomposition reference."""

from math import isqrt

BASE = 33
MAX_N = 1_024
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2


def _pack(parts: tuple[int, int, int, int]) -> int:
    a, b, c, d = parts
    return (((a * BASE) + b) * BASE + c) * BASE + d


def expected_result(values: list[int], *, input_length: int | None = None,
                    input_is_null: bool = False) -> int:
    length = len(values) if input_length is None else input_length
    if input_is_null or length != 1 or len(values) != 1:
        return -1
    n = values[0]
    if not 0 <= n <= MAX_N:
        return -1

    # Descending loops make the first valid tuple lexicographically greatest.
    for a in range(min(BASE - 1, isqrt(n)), -1, -1):
        remainder_a = n - a * a
        for b in range(min(a, isqrt(remainder_a)), -1, -1):
            remainder_b = remainder_a - b * b
            for c in range(min(b, isqrt(remainder_b)), -1, -1):
                remainder_c = remainder_b - c * c
                d = isqrt(remainder_c)
                if d <= c and d * d == remainder_c:
                    return _pack((a, b, c, d))
    return -2  # Lagrange's four-square theorem makes this unreachable.
