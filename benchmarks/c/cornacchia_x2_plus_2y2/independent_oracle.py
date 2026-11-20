"""Direct coordinate search oracle for Cornacchia's bounded target form."""

from __future__ import annotations

from collections.abc import Sequence

INVALID_RESULT = -1
MAX_PRIME = 1_000_000
MAX_PARSEABLE_INPUT_LENGTH = 3
PACK_BASE = 1024


def _read(values: Sequence[int] | None, input_is_null: bool,
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


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _read(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    prime, root = parsed
    if not _is_prime(prime) or (root * root + 2) % prime != 0:
        return INVALID_RESULT

    # Search x directly, then check whether (p-x^2)/2 is a positive square.
    for x in range(1, _isqrt(prime) + 1):
        remainder = prime - x * x
        if remainder <= 0 or remainder % 2 != 0:
            continue
        y_squared = remainder // 2
        y = _isqrt(y_squared)
        if y > 0 and y * y == y_squared:
            return x * PACK_BASE + y
    return INVALID_RESULT


def verify_candidate(values: Sequence[int] | None, result: int,
                     input_is_null: bool = False,
                     input_length: int | None = None) -> bool:
    return (type(result) is int
            and result == expected_result(values, input_is_null, input_length))
