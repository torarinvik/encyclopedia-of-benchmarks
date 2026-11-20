"""Sieve-and-trial-division reference for the bounded prefix scan."""

from __future__ import annotations

from collections.abc import Sequence

MAX_COUNT = 6
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
MAX_OUTPUT_BYTES = 24
WORKSPACE_BYTES = 256
INVALID_RESULT = -1
OUTPUT_ERROR = -2
_I64_MIN = -(1 << 63)
_I64_MAX = (1 << 63) - 1


def _first_primes(count: int) -> tuple[int, ...]:
    limit = 20
    is_prime = [True] * (limit + 1)
    is_prime[0] = is_prime[1] = False
    candidate = 2
    while candidate * candidate <= limit:
        if is_prime[candidate]:
            multiple = candidate * candidate
            while multiple <= limit:
                is_prime[multiple] = False
                multiple += candidate
        candidate += 1
    return tuple(value for value in range(2, limit + 1) if is_prime[value])[:count]


def _trial_prime(value: int) -> bool:
    if value < 2:
        return False
    divisor = 2
    while divisor <= value // divisor:
        if value % divisor == 0:
            return False
        divisor += 1
    return True


def _prime_prefixes(count: int) -> tuple[int, ...]:
    result: list[int] = []
    prefix = 0
    for prime in _first_primes(count):
        scale = 10
        while scale <= prime:
            scale *= 10
        prefix = prefix * scale + prime
        if _trial_prime(prefix):
            result.append(prefix)
    return tuple(result)


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> int | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not _I64_MIN <= value <= _I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) != 1 or not 0 <= values[0] <= MAX_COUNT:
        return None
    return values[0]


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (
                type(input_length) is not int
                or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and (not isinstance(values, (list, tuple)) or input_length != len(values))):
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    count = _parse(values, input_is_null, input_length)
    if count is None:
        return INVALID_RESULT, b""
    staged = b"".join(value.to_bytes(8, "little", signed=True)
                      for value in _prime_prefixes(count))
    if output_is_null or capacity is not None and capacity < len(staged):
        return OUTPUT_ERROR, b""
    return len(staged), staged
