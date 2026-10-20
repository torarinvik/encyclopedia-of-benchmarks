"""Independent direct-DFT oracle for the bounded forward NTT package."""
from __future__ import annotations

from collections.abc import Sequence

MOD = 998244353
ROOT = 3
MAX_N = 64
MAX_PARSEABLE_INPUT_LENGTH = MAX_N + 1
MAX_OUTPUT_BYTES = 4 * MAX_N
OUTPUT_ERROR = -2
INVALID = -1


def expected_output(values: Sequence[int] | None,
                    output_capacity: int | None = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or input_is_null or not isinstance(values, (list, tuple))
            or len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))):
        return INVALID, b""
    if any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return INVALID, b""
    n = values[0]
    if n < 1 or n > MAX_N or n & (n - 1) or len(values) != n + 1:
        return INVALID, b""
    coeffs = values[1:]
    if any(x < 0 or x >= MOD for x in coeffs):
        return INVALID, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return INVALID, b""
    if output_is_null or (output_capacity is not None and output_capacity < 4 * n):
        return OUTPUT_ERROR, b""
    omega = pow(ROOT, (MOD - 1) // n, MOD)
    result = []
    for k in range(n):
        value = 0
        for j, coefficient in enumerate(coeffs):
            value = (value + coefficient * pow(omega, j * k, MOD)) % MOD
        result.append(value)
    return 4 * n, b"".join(x.to_bytes(4, "little") for x in result)
