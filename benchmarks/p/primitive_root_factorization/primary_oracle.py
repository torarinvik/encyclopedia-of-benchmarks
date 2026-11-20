"""Factor-the-group-order criterion for least primitive-root search."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MIN_PRIME = 2
MAX_PRIME = 4093
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
WORKSPACE_BYTES = 4096


def _decode(values, input_is_null: bool, input_length: int | None) -> int | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) != 1:
        return None
    prime = values[0]
    if not MIN_PRIME <= prime <= MAX_PRIME:
        return None
    return prime


def _is_prime(value: int) -> bool:
    if value < 2:
        return False
    divisor = 2
    while divisor * divisor <= value:
        if value % divisor == 0:
            return False
        divisor += 1
    return True


def _distinct_prime_factors(value: int) -> list[int]:
    factors: list[int] = []
    divisor = 2
    remaining = value
    while divisor * divisor <= remaining:
        if remaining % divisor == 0:
            factors.append(divisor)
            while remaining % divisor == 0:
                remaining //= divisor
        divisor += 1
    if remaining > 1:
        factors.append(remaining)
    return factors


def _primitive_root(prime: int) -> int:
    if prime == 2:
        return 1
    group_order = prime - 1
    factors = _distinct_prime_factors(group_order)
    for candidate in range(2, prime):
        if all(pow(candidate, group_order // factor, prime) != 1
               for factor in factors):
            return candidate
    return -1


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    prime = _decode(values, input_is_null, input_length)
    if prime is None or not _is_prime(prime):
        return -1
    return _primitive_root(prime)
