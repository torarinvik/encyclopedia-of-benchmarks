"""Exact-combination oracle for bounded binomial coefficient prefixes."""

from __future__ import annotations

from math import comb

MODULUS = 998_244_353
MAX_T = 16
MAX_N = 128
MAX_INPUT_LENGTH = 1 + 2 * MAX_T
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 4 * MAX_T


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Sum exact Python binomial coefficients, then reduce each query."""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if (len(values) < 3 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or value < -(1 << 63) or value >= 1 << 63
                   for value in values)):
        return -1, b""
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return -1, b""
    count = values[0]
    if type(count) is not int or not 1 <= count <= MAX_T or len(values) != 1 + 2 * count:
        return -1, b""
    queries = []
    for index in range(count):
        n, k = values[1 + 2 * index:3 + 2 * index]
        if type(n) is not int or type(k) is not int or not 0 <= k <= n <= MAX_N:
            return -1, b""
        queries.append((n, k))
    required = 4 * count
    if type(output_is_null) is not bool:
        return -2, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return -2, b""
    if output_is_null or (output_capacity is not None and output_capacity < required):
        return -2, b""
    encoded = bytearray()
    for n, k in queries:
        value = sum(comb(n, index) for index in range(k + 1)) % MODULUS
        encoded.extend(value.to_bytes(4, "little"))
    return len(encoded), bytes(encoded)


def validate_output(values, output, **options):
    status, expected = expected_output(values, **options)
    return status >= 0 and len(output) == status and output == expected
