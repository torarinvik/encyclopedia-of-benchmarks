"""Independent bounded oracle for TSVC CrossingThresholds s1281."""
from __future__ import annotations

from collections.abc import Sequence

INVALID_RESULT = -1
OUTPUT_ERROR = -2
MAX_N = 16
MAX_PASSES = 8
MAX_INPUT_LENGTH = 2 + 5 * MAX_N
MAX_OUTPUT_BYTES = 16 * MAX_N


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                              or not 0 <= input_length <= MAX_INPUT_LENGTH)):
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if (len(values) < 2 or len(values) > MAX_INPUT_LENGTH
            or input_length is not None and input_length != len(values)
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63)
                   for v in values)):
        return INVALID_RESULT, b""
    n, passes = values[:2]
    if not 1 <= n <= MAX_N or not 1 <= passes <= MAX_PASSES or len(values) != 2 + 5*n:
        return INVALID_RESULT, b""
    body = values[2:]
    if any(v < -1 or v > 1 for v in body):
        return INVALID_RESULT, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    if output_is_null or capacity is not None and capacity < 16*n:
        return OUTPUT_ERROR, b""
    a = [float(v) for v in body[:n]]
    b = [float(v) for v in body[n:2*n]]
    c = [float(v) for v in body[2*n:3*n]]
    d = [float(v) for v in body[3*n:4*n]]
    e = [float(v) for v in body[4*n:5*n]]
    for _ in range(passes):
        for i in range(n):
            x = b[i] * c[i] + a[i] * d[i] + e[i]
            a[i] = x - 1.0
            b[i] = x
    out = b"".join(int(v).to_bytes(8, "little", signed=True) for v in (*a, *b))
    return len(out), out
