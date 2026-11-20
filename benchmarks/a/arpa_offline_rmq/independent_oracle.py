"""Direct bounded range scans for Arpa offline RMQ fixtures."""

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
    if not 1 <= n <= MAX_N or not 0 <= q <= MAX_Q or len(values) != 2 + n + 2 * q:
        return -1
    array = values[2:2 + n]
    if any(not -1000 <= value <= 1000 for value in array):
        return -1
    answers = []
    for ordinal in range(q):
        left, right = values[2 + n + 2 * ordinal: 4 + n + 2 * ordinal]
        if not 0 <= left <= right < n:
            return -1
        minimum = array[left]
        index = left
        for current in range(left + 1, right + 1):
            if array[current] < minimum:
                minimum = array[current]
                index = current
        answers.append(index)
    return sum((ordinal + 1) * (answer + 1) for ordinal, answer in enumerate(answers))
