"""Trial-division reference for the binomial-divisibility primality profile."""

from __future__ import annotations

from .primary_oracle import MAX_N, MAX_PARSEABLE_INPUT_LENGTH


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return -1
    if len(values) != 1 or not 2 <= values[0] <= MAX_N:
        return -1
    n = values[0]
    divisor = 2
    while divisor * divisor <= n:
        if n % divisor == 0:
            return 0
        divisor += 1
    return 1
