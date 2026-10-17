"""Independent oracle for bounded JavaScript-style subset enumeration."""
from __future__ import annotations

import struct

MAX_ITEMS = 12
MAX_SAFE_INTEGER = (1 << 53) - 1
MAX_OUTPUT_BYTES = 212_996
MAX_VALID_INPUT_LENGTH = MAX_ITEMS + 1
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(
    values: list[int] | tuple[int, ...] | None,
    output_capacity: int = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return output byte count and encoding, modeling ABI pointer failures."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_length is None:
        declared_length = len(values) if isinstance(values, (list, tuple)) else -1
    elif type(input_length) is int and input_length >= 0:
        declared_length = input_length
    else:
        return INVALID_RESULT, b""
    if type(output_capacity) is not int or not 0 <= output_capacity <= MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if input_is_null:
        if (values not in (None, [], ())
                or not 1 <= declared_length <= MAX_PARSEABLE_INPUT_LENGTH):
            return INVALID_RESULT, b""
        return INVALID_RESULT, b""
    if (not isinstance(values, (list, tuple))
            or len(values) < 1 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
            or declared_length != len(values)):
        return INVALID_RESULT, b""
    n = values[0]
    if n < 0 or n > MAX_ITEMS or len(values) != n + 1:
        return INVALID_RESULT, b""
    items = values[1:]
    if any(not -MAX_SAFE_INTEGER <= value <= MAX_SAFE_INTEGER for value in items):
        return INVALID_RESULT, b""
    output = bytearray(struct.pack("<I", 1 << n))
    for mask in range(1 << n):
        subset = [items[index] for index in range(n) if mask & (1 << index)]
        output.extend(struct.pack("<I", len(subset)))
        for value in subset:
            output.extend(struct.pack("<q", value))
    encoded = bytes(output)
    if len(encoded) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null or output_capacity < len(encoded):
        return OUTPUT_ERROR, b""
    return len(encoded), encoded
