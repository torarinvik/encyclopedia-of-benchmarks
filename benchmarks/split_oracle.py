"""Oracle for the bounded shared Python/F# split contract."""

from __future__ import annotations

from collections.abc import Sequence

MAX_TEXT_LENGTH = 256
MAX_INPUT_LENGTH = MAX_TEXT_LENGTH + 2
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
INVALID_RESULT = -1
INSUFFICIENT_OUTPUT_CAPACITY = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return encoded output length and the field sequence."""
    if type(input_is_null) is not bool or type(output_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null and output_is_null:
        return INVALID_RESULT, b""
    if input_length is not None and (type(input_length) is not int or input_length < 0):
        return INVALID_RESULT, b""
    if input_is_null:
        if (not isinstance(values, (list, tuple)) or values
                or type(input_length) is not int
                or not 1 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH):
            return INVALID_RESULT, b""
        return INVALID_RESULT, b""
    if values is None:
        return INVALID_RESULT, b""
    if (not isinstance(values, (list, tuple)) or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    if not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT, b""
    text_length, separator = values[0], values[1]
    if not 0 <= text_length <= MAX_TEXT_LENGTH or not 0 <= separator <= 127:
        return INVALID_RESULT, b""
    if len(values) != text_length + 2:
        return INVALID_RESULT, b""
    text_values = values[2:]
    if any(not 0 <= byte <= 127 for byte in text_values):
        return INVALID_RESULT, b""
    if text_values and (text_values[-1] == separator or separator not in text_values):
        return INVALID_RESULT, b""
    text = bytes(text_values)
    fields: list[bytes] = []
    start = 0
    for index, byte in enumerate(text):
        if byte == separator:
            fields.append(text[start:index])
            start = index + 1
    fields.append(text[start:])
    output = bytearray(len(fields).to_bytes(2, "little"))
    for field in fields:
        output.extend(len(field).to_bytes(2, "little"))
        output.extend(field)
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and capacity < len(output)):
        return INSUFFICIENT_OUTPUT_CAPACITY, b""
    return len(output), bytes(output)
