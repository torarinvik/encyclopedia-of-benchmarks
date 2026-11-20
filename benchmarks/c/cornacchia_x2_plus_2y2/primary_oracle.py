"""Cornacchia Euclidean descent for x^2 + 2*y^2 = p."""

from __future__ import annotations

from collections.abc import Sequence

MAX_PRIME = 1_000_000
PACK_BASE = 1024
MAX_X = 999
MAX_Y = 707
MAX_VALID_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3
MAX_RESULT = MAX_X * PACK_BASE + MAX_Y
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values) or input_length != 2:
        return None
    prime, root = values
    if not 3 <= prime <= MAX_PRIME or prime % 2 == 0 or not 1 <= root <= prime // 2:
        return None
    return prime, root


def _is_prime(value: int) -> bool:
    if value < 2:
        return False
    divisor = 2
    while divisor <= value // divisor:
        if value % divisor == 0:
            return False
        divisor = 3 if divisor == 2 else divisor + 2
    return True


def _isqrt(value: int) -> int:
    low = 0
    high = 1001
    while low + 1 < high:
        middle = (low + high) // 2
        if middle * middle <= value:
            low = middle
        else:
            high = middle
    return low


def _pack(x: int, y: int) -> int:
    return x * PACK_BASE + y


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    prime, root = parsed
    if not _is_prime(prime) or (root * root + 2) % prime != 0:
        return INVALID_RESULT

    previous = prime
    current = root
    limit = _isqrt(prime)
    while current > limit:
        previous, current = current, previous % current
    x = current
    remainder = prime - x * x
    if remainder <= 0 or remainder % 2 != 0:
        return INVALID_RESULT
    y_squared = remainder // 2
    y = _isqrt(y_squared)
    if y <= 0 or y * y != y_squared or x * x + 2 * y * y != prime:
        return INVALID_RESULT
    return _pack(x, y)
