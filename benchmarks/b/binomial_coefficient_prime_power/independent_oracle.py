"""Pascal-addition oracle for bounded binomial coefficients modulo p**e."""

from __future__ import annotations

MAX_P = 31
MAX_EXPONENT = 8
MAX_MODULUS = 1_000_000_000
MAX_QUERIES = 32
MAX_N = 128
MAX_INPUT_LENGTH = 3 + 2 * MAX_QUERIES
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 4 * MAX_QUERIES


def _is_prime(value: int) -> bool:
    if value < 2:
        return False
    return all(value % divisor for divisor in range(2, int(value ** 0.5) + 1))


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Build every queried row by addition, using no modular inverses."""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if (len(values) < 3 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or value < -(1 << 63) or value >= (1 << 63)
                   for value in values)):
        return -1, b""
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return -1, b""
    prime, exponent, count = values[0:3]
    if (type(prime) is not int or not 2 <= prime <= MAX_P or not _is_prime(prime)
            or type(exponent) is not int or not 1 <= exponent <= MAX_EXPONENT):
        return -1, b""
    modulus = prime ** exponent
    if modulus > MAX_MODULUS or type(count) is not int or not 0 <= count <= MAX_QUERIES:
        return -1, b""
    if len(values) != 3 + 2 * count:
        return -1, b""
    queries = []
    for query in range(count):
        n = values[3 + 2 * query]
        k = values[4 + 2 * query]
        if type(n) is not int or type(k) is not int or not 0 <= k <= n <= MAX_N:
            return -1, b""
        queries.append((n, k))

    if type(output_is_null) is not bool:
        return -2, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return -2, b""
    if count == 0:
        return 0, b""
    required = 4 * count
    if output_is_null or (output_capacity is not None and output_capacity < required):
        return -2, b""

    output = bytearray()
    for n, k in queries:
        row = [0] * (n + 1)
        row[0] = 1
        for upper in range(1, n + 1):
            for index in range(upper, 0, -1):
                row[index] = (row[index] + row[index - 1]) % modulus
        output.extend(row[k].to_bytes(4, "little"))
    return len(output), bytes(output)
