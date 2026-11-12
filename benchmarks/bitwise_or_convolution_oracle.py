"""Primary direct-pair oracle for bounded bitwise-OR convolution."""

from collections.abc import Sequence

MODULUS = 998_244_353
MAX_N = 8
MAX_SIZE = 1 << MAX_N
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_SIZE
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH
MAX_OUTPUT_BYTES = 8 * MAX_SIZE
MAX_WORKSPACE_BYTES = 2 * 8 * MAX_SIZE


def _parse(values: Sequence[int] | None, input_length: int | None):
    if (values is None or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or input_length is not None and
                (type(input_length) is not int or input_length != len(values))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n = values[0]
    if type(n) is not int or not 0 <= n <= MAX_N:
        return None
    size = 1 << n
    if len(values) != 1 + 2 * size:
        return None
    a = values[1:1 + size]
    b = values[1 + size:]
    if any(not 0 <= value < MODULUS for value in (*a, *b)):
        return None
    return a, b


def evaluate(values: Sequence[int] | None,
             input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_length)
    if parsed is None:
        return -1, b""
    a, b = parsed
    result = [0] * len(a)
    for i, x in enumerate(a):
        for j, y in enumerate(b):
            k = i | j
            result[k] = (result[k] + x * y) % MODULUS
    raw = b"".join(value.to_bytes(8, "little", signed=True) for value in result)
    return len(raw), raw


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and
                (type(input_length) is not int
                 or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)):
        return -1, b""
    if input_is_null:
        return -1, b""
    written, raw = evaluate(values, input_length)
    if written < 0:
        return written, raw
    if output_is_null or capacity is not None and capacity < written:
        return -2, b""
    return written, raw
