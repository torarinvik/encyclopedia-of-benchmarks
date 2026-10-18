"""Oracle for the bounded Java Floyd Pollard's rho source variant."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MIN_N = 2
MAX_N = 46340
MAX_STEP_LIMIT = 4096
INVALID_RESULT = -1
SOURCE_FAILURE_RESULT = 0
STEP_LIMIT_RESULT = -2


def _java_remainder(value: int, modulus: int) -> int:
    """Java `%` remainder, whose sign follows the dividend."""
    if value >= 0:
        return value % modulus
    return -((-value) % modulus)


def _next_value(value: int, modulus: int) -> int:
    return _java_remainder(value * value - 1, modulus)


def _gcd(left: int, right: int) -> int:
    while right:
        left, right = right, left % right
    return left


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Return a factor, 0 for source failure, -2 on the adapter cap, or -1 if invalid."""
    if (
        not isinstance(values, (list, tuple))
        or len(values) > 3
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
        or len(values) != 2
    ):
        return INVALID_RESULT

    n, step_limit = values
    if not MIN_N <= n <= MAX_N or not 1 <= step_limit <= MAX_STEP_LIMIT:
        return INVALID_RESULT

    x = y = 2
    for _ in range(step_limit):
        x = _next_value(x, n)
        y = _next_value(_next_value(y, n), n)
        divisor = _gcd(abs(x - y), n)
        if divisor == 1:
            continue
        return SOURCE_FAILURE_RESULT if divisor == n else divisor
    return STEP_LIMIT_RESULT
