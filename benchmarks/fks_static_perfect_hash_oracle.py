"""Direct-set membership oracle for the bounded FKS static dictionary."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 8
MAX_Q = 8
MAX_VALID_INPUT_LENGTH = 2 + MAX_N + MAX_Q
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT
    actual_length = len(values) if input_length is None else input_length
    if (type(actual_length) is not int or actual_length < 2
            or actual_length > MAX_PARSEABLE_INPUT_LENGTH or actual_length != len(values)):
        return INVALID_RESULT
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return INVALID_RESULT
    n, q = values[0], values[1]
    if not 0 <= n <= MAX_N or not 0 <= q <= MAX_Q or actual_length != 2 + n + q:
        return INVALID_RESULT
    keys = values[2:2 + n]
    queries = values[2 + n:]
    if any(not 0 <= key <= 255 for key in keys + queries):
        return INVALID_RESULT
    if len(set(keys)) != n:
        return INVALID_RESULT
    present = set(keys)
    return sum((1 << index) for index, query in enumerate(queries) if query in present)
