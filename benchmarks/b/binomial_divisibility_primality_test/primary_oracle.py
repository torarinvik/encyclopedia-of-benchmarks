"""Pascal-row modulo-n reference for the binomial primality criterion."""

from __future__ import annotations

MAX_N = 1000
MAX_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
WORKSPACE_BYTES = 8192


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
    coefficients = [0] * (n + 1)
    coefficients[0] = 1
    for degree in range(1, n + 1):
        coefficients[degree] = 1
        for index in range(degree - 1, 0, -1):
            coefficients[index] = (coefficients[index] + coefficients[index - 1]) % n
    return int(all(value == 0 for value in coefficients[1:n]))
