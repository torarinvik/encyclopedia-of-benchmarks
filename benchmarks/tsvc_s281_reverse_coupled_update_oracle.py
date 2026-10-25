"""Independent oracle for the bounded TSVC s281 reverse-coupled update."""

from __future__ import annotations

from collections.abc import Sequence

INVALID_RESULT = -1
OUTPUT_ERROR = -2
MIN_N = 1
MAX_N = 16
MIN_PASSES = 1
MAX_PASSES = 8
MAX_INPUT_LENGTH = 2 + 3 * MAX_N
MAX_OUTPUT_BYTES = 16 * MAX_N
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if (
        type(output_is_null) is not bool
        or type(input_is_null) is not bool
        or capacity is not None
        and (type(capacity) is not int or capacity < 0)
        or input_length is not None
        and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH)
    ):
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if (
        not 2 <= len(values) <= MAX_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
        or input_length is not None and input_length != len(values)
    ):
        return INVALID_RESULT, b""

    n, passes = values[:2]
    if not MIN_N <= n <= MAX_N or not MIN_PASSES <= passes <= MAX_PASSES:
        return INVALID_RESULT, b""
    if len(values) != 2 + 3 * n:
        return INVALID_RESULT, b""
    a_values = values[2:2 + n]
    b_values = values[2 + n:2 + 2 * n]
    c_values = values[2 + 2 * n:]
    if (any(not -2 <= value <= 2 for value in a_values)
            or any(not -2 <= value <= 2 for value in b_values)
            or any(not -1 <= value <= 1 for value in c_values)):
        return INVALID_RESULT, b""

    # Every value stays an exactly representable integer in binary64 under the
    # declared bounds; the float operations retain the source's double type.
    a = [float(value) for value in a_values]
    b = [float(value) for value in b_values]
    c = [float(value) for value in c_values]
    for _ in range(passes):
        for i in range(n):
            x = a[n - i - 1] + b[i] * c[i]
            a[i] = x - 1.0
            b[i] = x

    output = bytearray()
    for value in (*a, *b):
        output.extend(int(value).to_bytes(8, "little", signed=True))
    if output_is_null or capacity is not None and capacity < len(output):
        return OUTPUT_ERROR, b""
    return len(output), bytes(output)
