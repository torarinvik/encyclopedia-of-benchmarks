"""Independent trial-division reference for bounded prime-count fixtures."""

from __future__ import annotations

from collections.abc import Sequence

INVALID_RESULT = -1
MIN_LIMIT = 2
MAX_LIMIT = 1024
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2


def _parse(values: Sequence[int] | None, is_null: bool,
           declared_length: int | None) -> int | None:
    if type(is_null) is not bool or is_null or not isinstance(values, (list, tuple)):
        return None
    actual_length = len(values) if declared_length is None else declared_length
    if (type(actual_length) is not int or actual_length != len(values)
            or actual_length < 1 or actual_length > MAX_PARSEABLE_INPUT_LENGTH):
        return None
    for item in values:
        if type(item) is not int or not -(1 << 63) <= item < (1 << 63):
            return None
    if actual_length != 1:
        return None
    candidate = values[0]
    return candidate if MIN_LIMIT <= candidate <= MAX_LIMIT else None


def _is_prime(candidate: int) -> bool:
    if candidate < 2:
        return False
    divisor = 2
    while divisor <= candidate // divisor:
        if candidate % divisor == 0:
            return False
        divisor += 1
    return True


def expected_result(values: Sequence[int] | None,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    limit = _parse(values, input_is_null, input_length)
    if limit is None:
        return INVALID_RESULT
    return sum(1 for candidate in range(2, limit + 1) if _is_prime(candidate))
