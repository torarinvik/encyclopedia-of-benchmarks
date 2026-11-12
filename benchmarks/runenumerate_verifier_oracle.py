"""Exhaustive interval oracle for the bounded maximal-runs profile."""

import struct

MAX_N = 24
MAX_PARSEABLE_INPUT_LENGTH = MAX_N + 1
MAX_RUNS_BOUND = (MAX_N // 2) * (MAX_N - MAX_N // 2)
MAX_OUTPUT_BYTES = 8 * (1 + 3 * MAX_RUNS_BOUND)
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _has_period(text, left, right, period):
    return all(text[index] == text[index - period]
               for index in range(left + period, right))


def _enumerate(text):
    n = len(text)
    result = []
    for period in range(1, n // 2 + 1):
        for left in range(n):
            for right in range(left + 2 * period, n + 1):
                if not _has_period(text, left, right, period):
                    continue
                if any(_has_period(text, left, right, smaller)
                       for smaller in range(1, period)):
                    continue
                extends_left = (left > 0 and
                                text[left - 1] == text[left + period - 1])
                extends_right = (right < n and
                                 text[right] == text[right - period])
                if not extends_left and not extends_right:
                    result.append((period, left, right))
    return sorted(result)


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 2
            or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values)
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT, b""
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != n + 1:
        return INVALID_RESULT, b""
    text = values[1:]
    if any(not 0 <= value < 26 for value in text):
        return INVALID_RESULT, b""
    runs = _enumerate(text)
    output = bytearray(struct.pack("<q", len(runs)))
    for period, left, right in runs:
        output.extend(struct.pack("<qqq", period, left, right))
    if type(output_is_null) is not bool:
        return OUTPUT_ERROR, b""
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if type(effective_capacity) is not int or effective_capacity < 0:
        return OUTPUT_ERROR, b""
    if output_is_null or effective_capacity < len(output):
        return OUTPUT_ERROR, b""
    return len(output), bytes(output)
