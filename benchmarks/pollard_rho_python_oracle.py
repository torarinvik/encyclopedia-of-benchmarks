"""Oracle for the bounded Python Floyd Pollard's rho source variant."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_PARSEABLE_LENGTH = 6
INVALID_RESULT = -1
NO_FACTOR_RESULT = 0


def _gcd(left: int, right: int) -> int:
    while right:
        left, right = right, left % right
    return left


def _advance(value: int, step: int, modulus: int) -> int:
    return (value * value + step) % modulus


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Return the source factor, 0 for bounded exhaustion, or -1 if invalid."""
    if (
        not isinstance(values, (list, tuple))
        or len(values) > MAX_PARSEABLE_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
        or len(values) != 5
    ):
        return INVALID_RESULT

    num, seed, step, attempts, step_limit = values
    if (
        not 2 <= num <= 1_000_000
        or not 0 <= seed < num
        or not 0 <= step <= 1_000
        or not 1 <= attempts <= 8
        or not 1 <= step_limit <= 64
    ):
        return INVALID_RESULT

    if num > 2 and num % 2 == 0:
        return 2

    for _ in range(attempts):
        tortoise = hare = seed
        for _ in range(step_limit):
            tortoise = _advance(tortoise, step, num)
            hare = _advance(_advance(hare, step, num), step, num)
            divisor = _gcd(hare - tortoise, num)
            if divisor == 1:
                continue
            if divisor < num:
                return divisor
            break

        seed = hare
        step += 1

    return NO_FACTOR_RESULT
