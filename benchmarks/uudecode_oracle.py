"""Bounded oracle for BitBench's fixed-header uudecode benchmark."""

from __future__ import annotations

from collections.abc import Sequence

MAX_INPUT_BYTES = 4096
MAX_PARSEABLE_INPUT_VALUES = MAX_INPUT_BYTES + 1
MAX_OUTPUT_BYTES = 2949
HEADER = b"begin 755 uustart.file \n"
TRAILER = b" \nend"
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _decode(values: Sequence[int]) -> bytes | None:
    """Decode the source format within the package's bounded stream profile."""
    data = bytes(values)
    if not data.startswith(HEADER) or len(data) < len(HEADER) + len(TRAILER):
        return None

    cursor = len(HEADER)
    decoded = bytearray()
    while cursor < len(data):
        count_symbol = data[cursor]
        cursor += 1
        if count_symbol == 32:
            if data[cursor:cursor + 2] != b"\n" or data[cursor + 2:] != b"end":
                return None
            return bytes(decoded)

        count = count_symbol - 32
        if not 1 <= count <= 45:
            return None
        quartet_count = (count + 2) // 3
        encoded_length = quartet_count * 4
        line_end = cursor + encoded_length
        if line_end >= len(data) or data[line_end] != 10:
            return None
        encoded = data[cursor:line_end]
        if any(symbol < 32 or symbol > 95 for symbol in encoded):
            return None

        emitted = 0
        for group_start in range(0, encoded_length, 4):
            first, second, third, fourth = (
                symbol - 32 for symbol in encoded[group_start:group_start + 4])
            decoded.append(((first << 2) | (second >> 4)) & 255)
            emitted += 1
            if emitted < count:
                decoded.append(((second << 4) | (third >> 2)) & 255)
                emitted += 1
            if emitted < count:
                decoded.append(((third << 6) | fourth) & 255)
                emitted += 1

        cursor = line_end + 1
    return None


def expected_output(values: Sequence[int] | None,
                    output_capacity: int | None = None,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    """Return decoded bytes or the ABI invalid/capacity result."""
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or (output_capacity is not None
                and (type(output_capacity) is not int or output_capacity < 0))
            or (input_length is not None
                and (type(input_length) is not int or input_length < 0))):
        return INVALID_RESULT, b""
    if (input_is_null or values is None or not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_VALUES
            or (input_length is not None and input_length != len(values))
            or len(values) > MAX_INPUT_BYTES
            or any(type(value) is not int or not 0 <= value <= 255 for value in values)):
        return INVALID_RESULT, b""

    decoded = _decode(values)
    if decoded is None:
        return INVALID_RESULT, b""
    if len(decoded) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null or (output_capacity is not None and output_capacity < len(decoded)):
        return OUTPUT_ERROR, b""
    return len(decoded), decoded
