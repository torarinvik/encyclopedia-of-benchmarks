"""Independent reference: sieve rational primes through the norm bound."""

from __future__ import annotations

from collections.abc import Sequence

INVALID_RESULT = -1
MAX_COORDINATE = 10_000
MAX_VALID_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3
MAX_NORM = 2 * MAX_COORDINATE * MAX_COORDINATE
MAX_SIEVE_LIMIT = 14_142
WORKSPACE_BYTES = 128


def _read_frame(words: Sequence[int], is_null: bool, length: int) -> tuple[int, int] | None:
    if (not isinstance(words, (tuple, list)) or type(is_null) is not bool or is_null
            or type(length) is not int or length != len(words)
            or not 1 <= length <= MAX_PARSEABLE_INPUT_LENGTH):
        return None
    for word in words:
        if type(word) is not int or word < -(1 << 63) or word >= (1 << 63):
            return None
    if length != MAX_VALID_INPUT_LENGTH:
        return None
    real, imaginary = words[0], words[1]
    if (real < -MAX_COORDINATE or real > MAX_COORDINATE
            or imaginary < -MAX_COORDINATE or imaginary > MAX_COORDINATE):
        return None
    return real, imaginary


def _prime_table() -> bytearray:
    prime = bytearray(b"\x01") * (MAX_SIEVE_LIMIT + 1)
    prime[0] = 0
    prime[1] = 0
    candidate = 2
    while candidate * candidate <= MAX_SIEVE_LIMIT:
        if prime[candidate]:
            multiple = candidate * candidate
            while multiple <= MAX_SIEVE_LIMIT:
                prime[multiple] = 0
                multiple += candidate
        candidate += 1
    return prime


def _sieved_prime(value: int, prime: bytearray) -> bool:
    if value < 2:
        return False
    if value <= MAX_SIEVE_LIMIT:
        return bool(prime[value])
    divisor = 2
    while divisor * divisor <= value:
        if prime[divisor] and value % divisor == 0:
            return False
        divisor += 1
    return True


def _classify_from_table(real: int, imaginary: int, prime: bytearray) -> int:
    if real == 0 and imaginary == 0:
        return 0
    if real == 0 or imaginary == 0:
        axis_value = -real if real < 0 else real
        if real == 0:
            axis_value = -imaginary if imaginary < 0 else imaginary
        return int(axis_value % 4 == 3 and _sieved_prime(axis_value, prime))
    norm = real * real + imaginary * imaginary
    return int(_sieved_prime(norm, prime))


def expected_result(values: Sequence[int], input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    effective_length = (len(values) if input_length is None and isinstance(values, (list, tuple))
                        else input_length)
    if effective_length is None:
        return INVALID_RESULT
    coordinates = _read_frame(values, input_is_null, effective_length)
    if coordinates is None:
        return INVALID_RESULT
    return _classify_from_table(*coordinates, _prime_table())
