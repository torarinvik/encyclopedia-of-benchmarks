"""Reference oracle for the bounded Go Pollard's rho contract."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MIN_N = 2
MAX_N = 111155
EXACT_INPUT_LENGTH = 1
MAX_INPUT_LENGTH = 2
INVALID_RESULT = -1
SOURCE_FAILURE_RESULT = 0


def _next_value(n: int, x: int) -> int:
    return (x * x + 1) % n


def _gcd(left: int, right: int) -> int:
    while right != 0:
        left, right = right, left % right
    return left


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Return the source factor, 0 for its gcd==n error, or -1 if invalid."""
    if (
        not isinstance(values, (list, tuple))
        or len(values) > MAX_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return INVALID_RESULT
    if len(values) != EXACT_INPUT_LENGTH:
        return INVALID_RESULT

    n = values[0]
    if not MIN_N <= n <= MAX_N:
        return INVALID_RESULT

    x = 2
    y = 2
    divisor = 1
    while divisor == 1:
        x = _next_value(n, x)
        y = _next_value(n, _next_value(n, y))
        divisor = _gcd(abs(x - y), n)
    if divisor == n:
        return SOURCE_FAILURE_RESULT
    return divisor
