"""Independent quadratic oracle for the bounded online convolution contract."""
from __future__ import annotations

from collections.abc import Sequence

MOD = 998244353
MAX_N = 16
MAX_PARSEABLE_INPUT_LENGTH = 1 + 2 * MAX_N
MAX_OUTPUT_BYTES = 4 * MAX_N


def expected_output(values: Sequence[int] | None,
                    output_capacity: int | None = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or input_is_null or not isinstance(values, (list, tuple))
            or len(values) < 3 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))):
        return -1, b""
    if any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return -1, b""
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != 1 + 2 * n:
        return -1, b""
    a = values[1:1 + n]
    b = values[1 + n:]
    if any(x < 0 or x >= MOD for x in (*a, *b)):
        return -1, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    if output_is_null or (output_capacity is not None and output_capacity < 4 * n):
        return -2, b""
    result = [sum(a[j] * b[k - j] for j in range(k + 1)) % MOD for k in range(n)]
    return 4 * n, b"".join(x.to_bytes(4, "little") for x in result)
