"""Forward flat-array painting, independent of the successor DSU."""

from __future__ import annotations

from .primary_oracle import I64_MAX, I64_MIN, MAX_N, MAX_Q, MAX_PARSEABLE_INPUT_LENGTH


def expected_result(values, input_is_null=False, input_length=None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return -1
    if len(values) < 2:
        return -1
    n, q = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= q <= MAX_Q or len(values) != 2 + 3 * q:
        return -1
    final = [0] * n
    for j in range(q):
        left, right, color = values[2 + 3 * j: 5 + 3 * j]
        if not 0 <= left <= right < n or not -1000 <= color <= 1000:
            return -1
        for index in range(left, right + 1):
            final[index] = color
    return sum((index + 1) * (color + 1001) for index, color in enumerate(final))
