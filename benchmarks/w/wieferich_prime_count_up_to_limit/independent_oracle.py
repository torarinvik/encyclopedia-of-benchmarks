"""Trial-prime scan with a linear exponent recurrence for independent checking."""

from __future__ import annotations

from collections.abc import Sequence

MAX_LIMIT = 5_000
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> int | None:
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    actual_length = len(values) if input_length is None else input_length
    if actual_length != len(values) or len(values) != MAX_VALID_INPUT_LENGTH:
        return None
    limit = values[0]
    return limit if 2 <= limit <= MAX_LIMIT else None


def _is_prime_by_trial_division(value: int) -> bool:
    if value < 2:
        return False
    divisor = 2
    while divisor * divisor <= value:
        if value % divisor == 0:
            return False
        divisor += 1
    return True


def wieferich_prime_count_up_to_limit_independent(
    values: Sequence[int] | None,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    limit = _parse(values, input_is_null, input_length)
    if limit is None:
        return INVALID_RESULT
    count = 0
    for candidate in range(3, limit + 1, 2):
        if not _is_prime_by_trial_division(candidate):
            continue
        modulus = candidate * candidate
        residue = 1
        for _ in range(candidate - 1):
            residue = (2 * residue) % modulus
        if residue == 1:
            count += 1
    return count
