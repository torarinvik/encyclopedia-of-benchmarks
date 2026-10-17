"""Oracle for the bounded Go Moser-de Bruijn sequence adapter."""

from __future__ import annotations

from collections.abc import Sequence

MAX_COUNT = 64
MAX_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 3
MAX_OUTPUT_BYTES = 8 * MAX_COUNT
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
SIZE_T_MAX = (1 << 64) - 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _term(index: int) -> int:
    if index == 0 or index == 1:
        return index
    if index % 2 == 0:
        return 4 * _term(index // 2)
    return 4 * _term(index // 2) + 1


def expected_output(
    values: Sequence[int],
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the byte count and little-endian signed-i64 sequence payload."""
    if input_length is None:
        declared_length = len(values) if isinstance(values, (list, tuple)) else -1
    elif type(input_length) is int and input_length >= 0:
        declared_length = input_length
    else:
        return INVALID_RESULT, b""

    if (not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)
            or type(input_is_null) is not bool
            or (input_is_null and (len(values) != 0
                                   or not 1 <= declared_length <= MAX_PARSEABLE_INPUT_LENGTH))
            or (not input_is_null and declared_length != len(values))
            or declared_length > MAX_PARSEABLE_INPUT_LENGTH):
        return INVALID_RESULT, b""
    if input_is_null or declared_length != MAX_INPUT_LENGTH:
        return INVALID_RESULT, b""

    count = values[0]
    if not -MAX_COUNT <= count <= MAX_COUNT:
        return INVALID_RESULT, b""
    if (type(output_is_null) is not bool
            or (output_capacity is not None
                and (type(output_capacity) is not int
                     or not 0 <= output_capacity <= SIZE_T_MAX))):
        return INVALID_RESULT, b""

    terms = [_term(index) for index in range(max(count, 0))]
    output = b"".join(term.to_bytes(8, byteorder="little", signed=True) for term in terms)
    if output and (output_is_null or
                   (output_capacity is not None and output_capacity < len(output))):
        return OUTPUT_ERROR, b""
    return len(output), output
