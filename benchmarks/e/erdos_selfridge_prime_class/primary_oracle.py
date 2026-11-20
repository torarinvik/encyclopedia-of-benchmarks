"""Primary reference: recursively factor the selected neighbor of each prime."""

from __future__ import annotations

from collections.abc import Sequence

ALGORITHM = "erdos_selfridge_prime_class"
INVALID_RESULT = -1
MAX_PRIME = 100_000
MAX_VALID_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3
MAX_CLASS = 17
WORKSPACE_BYTES = 4_096


def _decode(values: Sequence[int], input_is_null: bool,
            input_length: int) -> tuple[int, int] | None:
    if (not isinstance(values, (tuple, list)) or type(input_is_null) is not bool
            or input_is_null or type(input_length) is not int
            or input_length != len(values)
            or not 1 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH):
        return None
    if any(type(word) is not int or word < -(1 << 63) or word >= (1 << 63)
           for word in values):
        return None
    if input_length != MAX_VALID_INPUT_LENGTH:
        return None
    prime, direction = values
    if type(prime) is not int or not 2 <= prime <= MAX_PRIME:
        return None
    if type(direction) is not int or direction not in (-1, 1):
        return None
    return prime, direction


def _trial_prime(value: int) -> bool:
    if value < 2:
        return False
    if value % 2 == 0:
        return value == 2
    divisor = 3
    while divisor <= value // divisor:
        if value % divisor == 0:
            return False
        divisor += 2
    return True


def _distinct_factors(value: int) -> list[int]:
    factors: list[int] = []
    divisor = 2
    while divisor <= value // divisor:
        if value % divisor == 0:
            factors.append(divisor)
            while value % divisor == 0:
                value //= divisor
        divisor += 1
    if value > 1:
        factors.append(value)
    return factors


def _recursive_class(prime: int, direction: int, memo: dict[int, int]) -> int:
    if prime in memo:
        return memo[prime]
    result = 1
    neighbor = prime + direction
    for factor in _distinct_factors(neighbor):
        if factor > 3:
            result = max(result, 1 + _recursive_class(factor, direction, memo))
    memo[prime] = result
    return result


def expected_result(values: Sequence[int], input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    effective_length = (len(values) if input_length is None and isinstance(values, (list, tuple))
                        else input_length)
    if effective_length is None:
        return INVALID_RESULT
    decoded = _decode(values, input_is_null, effective_length)
    if decoded is None:
        return INVALID_RESULT
    prime, direction = decoded
    if not _trial_prime(prime):
        return INVALID_RESULT
    return _recursive_class(prime, direction, {})

