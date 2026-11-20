"""Trial-division reference for the first bounded Fortunate numbers."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 10
SEARCH_MAX = 64
MAX_PRIMORIAL = 6_469_693_230
MAX_CANDIDATE = 6_469_693_294
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
WORKSPACE_BYTES = 128
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> int | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    actual = len(values) if input_length is None else input_length
    if (type(actual) is not int or actual != len(values)
            or len(values) != MAX_VALID_INPUT_LENGTH):
        return None
    n = values[0]
    return n if 1 <= n <= MAX_N else None


def _is_prime_trial(value: int) -> bool:
    if value < 2:
        return False
    divisor = 2
    while divisor <= value // divisor:
        if value % divisor == 0:
            return False
        divisor += 1
    return True


def _fortunate(n: int) -> int:
    primorial = 1
    found_primes = 0
    candidate = 2
    while found_primes < n:
        if _is_prime_trial(candidate):
            primorial *= candidate
            found_primes += 1
        candidate += 1
    for offset in range(2, SEARCH_MAX + 1):
        if _is_prime_trial(primorial + offset):
            return offset
    return -2


def expected_result(values: Sequence[int] | None,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Return F_n, -1 for invalid framing, or -2 if the bounded search expires."""
    n = _parse(values, input_is_null, input_length)
    return -1 if n is None else _fortunate(n)
