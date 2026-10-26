"""Independent model for the bounded SIC/XE relocation field addition."""
from collections.abc import Sequence

MAX_HALF_BYTES = 6
MAX_DELTA = 65_535
MAX_INPUT_LENGTH = 8
MAX_OUTPUT_BYTES = 3
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(values: Sequence[int] | None, output_capacity: int | None = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or (input_length is not None and
                (type(input_length) is not int or input_length != len(values)))
            or any(type(v) is not int for v in values)):
        return INVALID_RESULT, b""
    half_bytes, delta = values[:2]
    if not 1 <= half_bytes <= MAX_HALF_BYTES or not -MAX_DELTA <= delta <= MAX_DELTA:
        return INVALID_RESULT, b""
    width = (half_bytes + 1) // 2
    if len(values) != 2 + width or any(not 0 <= v <= 255 for v in values[2:]):
        return INVALID_RESULT, b""
    field = 0
    for byte in values[2:]:
        field = field * 256 + byte
    adjusted = field + delta
    if adjusted < 0:
        return INVALID_RESULT, b""
    adjusted &= (1 << (8 * width)) - 1
    result = bytes((adjusted >> (8 * shift)) & 255 for shift in range(8 * width - 8, -1, -8))
    if (type(output_is_null) is not bool or type(output_capacity) is not int
            or output_capacity < 0):
        return INVALID_RESULT, b""
    if output_is_null or output_capacity < width:
        return OUTPUT_ERROR, b""
    return width, result


oracle = expected_output
