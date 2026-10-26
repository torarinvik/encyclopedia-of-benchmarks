"""Independent bounded oracle for TSVC ControlLoops vtv."""
from __future__ import annotations
from collections.abc import Sequence

INVALID_RESULT = -1
OUTPUT_ERROR = -2
MAX_N = 32
MAX_PASSES = 8
MAX_INPUT_LENGTH = 2 + 2 * MAX_N
MAX_OUTPUT_BYTES = 8 * MAX_N


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
    if (len(values) < 4 or len(values) > MAX_INPUT_LENGTH
            or input_length is not None and input_length != len(values)
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values)):
        return INVALID_RESULT, b""
    n, passes = values[:2]
    if not 1 <= n <= MAX_N or not 1 <= passes <= MAX_PASSES or len(values) != 2 + 2*n:
        return INVALID_RESULT, b""
    data = values[2:]
    if any(not -2 <= v <= 2 for v in data):
        return INVALID_RESULT, b""
    if output_is_null or capacity is not None and capacity < 8*n:
        return OUTPUT_ERROR, b""
    a = [float(v) for v in data[:n]]
    b = [float(v) for v in data[n:]]
    for _ in range(passes):
        for i in range(n):
            a[i] *= b[i]
    out = b"".join(int(v).to_bytes(8, "little", signed=True) for v in a)
    return len(out), out
