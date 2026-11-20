"""Bounded Fermat difference-of-squares factor search."""

from __future__ import annotations

from math import isqrt
from typing import Sequence

ALGORITHM = "fermat_factorization"
MAX_NUMBER = 1_000_000_000_000
MAX_STEPS = 4096
MAX_VALID_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3
INVALID_RESULT = -1
WORKSPACE_BYTES = 256


def expected_result(values: Sequence[int] | None,
                    algorithm: str = ALGORITHM,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (algorithm != ALGORITHM or not isinstance(values, (list, tuple))
            or type(input_is_null) is not bool or input_is_null
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or len(values) != MAX_VALID_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    number, max_steps = values
    if (number < 3 or number > MAX_NUMBER or number % 2 == 0
            or max_steps < 0 or max_steps > MAX_STEPS):
        return INVALID_RESULT

    candidate = isqrt(number)
    if candidate * candidate < number:
        candidate += 1
    for _ in range(max_steps):
        difference = candidate * candidate - number
        root = isqrt(difference)
        if root * root == difference:
            factor = candidate - root
            if 1 < factor < number:
                return factor
        candidate += 1
    return 0
