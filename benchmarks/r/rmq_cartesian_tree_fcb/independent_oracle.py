"""Direct range-scan oracle for the Cartesian-tree FCB RMQ profile."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_N = 64
MAX_Q = 64
MAX_VALID_INPUT_LENGTH = 194
MAX_PARSEABLE_INPUT_LENGTH = 195
MAX_OUTPUT_BYTES = 65


def _decode(values, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values) or len(values) < 2:
        return None
    n, q = values[0], values[1]
    if not 1 <= n <= MAX_N or not 0 <= q <= MAX_Q or len(values) != 2 + n + 2 * q:
        return None
    data = values[2:2 + n]
    if any(not -1000 <= value <= 1000 for value in data):
        return None
    queries = []
    cursor = 2 + n
    while cursor < len(values):
        lo, hi = values[cursor], values[cursor + 1]
        if not 0 <= lo <= hi < n:
            return None
        queries.append((lo, hi))
        cursor += 2
    return data, queries


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None or type(output_is_null) is not bool:
        return -1, b""
    data, queries = decoded
    required = len(queries) + 1
    if (output_is_null or (output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < required))):
        return -2, b""
    indices = []
    for lo, hi in queries:
        best = lo
        for at in range(lo + 1, hi + 1):
            if data[at] < data[best]:
                best = at
        indices.append(best)
    return required, bytes([len(indices), *indices])


def expected_result(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    return expected_output(values, output_capacity, output_is_null,
                          input_is_null, input_length)[0]
