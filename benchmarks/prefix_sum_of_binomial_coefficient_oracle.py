"""Modular coefficient-ratio oracle for bounded binomial prefixes."""

from __future__ import annotations

MODULUS = 998_244_353
MAX_T = 16
MAX_N = 128
MAX_INPUT_LENGTH = 1 + 2 * MAX_T
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 4 * MAX_T


def _inverses() -> list[int]:
    inverses = [0] * (MAX_N + 1)
    inverses[1] = 1
    for value in range(2, MAX_N + 1):
        inverses[value] = MODULUS - (MODULUS // value) * inverses[MODULUS % value] % MODULUS
    return inverses


def _parse(values, input_length, input_is_null):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if (len(values) < 3 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < 1 << 63
                   for value in values)):
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    count = values[0]
    if type(count) is not int or not 1 <= count <= MAX_T:
        return None
    if len(values) != 1 + 2 * count:
        return None
    queries = []
    for index in range(count):
        n, k = values[1 + 2 * index:3 + 2 * index]
        if type(n) is not int or type(k) is not int or not 0 <= k <= n <= MAX_N:
            return None
        queries.append((n, k))
    return queries


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Return `(byte_count, little-endian uint32 residues)` for each query."""
    queries = _parse(values, input_length, input_is_null)
    if queries is None:
        return -1, b""
    required = 4 * len(queries)
    if type(output_is_null) is not bool:
        return -2, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return -2, b""
    if output_is_null or (output_capacity is not None and output_capacity < required):
        return -2, b""

    inverse = _inverses()
    output = bytearray()
    for n, k in queries:
        coefficient = 1
        prefix = 1
        for index in range(k):
            coefficient = coefficient * (n - index) % MODULUS
            coefficient = coefficient * inverse[index + 1] % MODULUS
            prefix = (prefix + coefficient) % MODULUS
        output.extend(prefix.to_bytes(4, "little"))
    return len(output), bytes(output)
