"""Independent oracle for the bounded C# dictionary-based text translator."""

from __future__ import annotations

from collections.abc import Sequence


MAX_KEY_COUNT = 4
MAX_KEY_LENGTH = 4
MAX_VALUE_LENGTH = 4
MAX_TEXT_LENGTH = 64
MAX_VALID_INPUT_LENGTH = 2 + MAX_KEY_COUNT * (2 + MAX_KEY_LENGTH + MAX_VALUE_LENGTH) + MAX_TEXT_LENGTH
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1  # one extra value for malformed framing
MAX_OUTPUT_BYTES = MAX_TEXT_LENGTH * MAX_VALUE_LENGTH
MIN_PRINTABLE_ASCII = 32
MAX_PRINTABLE_ASCII = 126
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _valid_i64_array(values: object) -> bool:
    return (isinstance(values, (list, tuple))
            and 2 <= len(values) <= MAX_INPUT_LENGTH
            and all(type(value) is int and I64_MIN <= value <= I64_MAX
                    for value in values))


def _translate(values: Sequence[int]) -> bytes | None:
    """Return translated bytes, or ``None`` when packed input is invalid."""
    if not _valid_i64_array(values):
        return None

    key_count, text_length = values[0], values[1]
    if not 0 <= key_count <= MAX_KEY_COUNT or not 0 <= text_length <= MAX_TEXT_LENGTH:
        return None

    cursor = 2
    mapping: dict[bytes, bytes] = {}
    for _ in range(key_count):
        if cursor + 2 > len(values):
            return None
        key_length, value_length = values[cursor], values[cursor + 1]
        cursor += 2
        if (not 1 <= key_length <= MAX_KEY_LENGTH
                or not 0 <= value_length <= MAX_VALUE_LENGTH
                or cursor + key_length + value_length > len(values)):
            return None

        key_values = values[cursor:cursor + key_length]
        cursor += key_length
        value_values = values[cursor:cursor + value_length]
        cursor += value_length
        if (any(not MIN_PRINTABLE_ASCII <= byte <= MAX_PRINTABLE_ASCII
                for byte in (*key_values, *value_values))):
            return None

        key = bytes(key_values)
        if key in mapping:
            return None
        mapping[key] = bytes(value_values)

    if cursor + text_length != len(values):
        return None
    text_values = values[cursor:]
    if any(not MIN_PRINTABLE_ASCII <= byte <= MAX_PRINTABLE_ASCII
           for byte in text_values):
        return None
    text = bytes(text_values)

    output = bytearray()
    start = 0
    while start < len(text):
        matched = False
        maximum_match_length = min(MAX_KEY_LENGTH, len(text) - start)
        for key_length in range(1, maximum_match_length + 1):
            key = text[start:start + key_length]
            if key in mapping:
                output.extend(mapping[key])
                start += key_length
                matched = True
                break
        if not matched:
            # The source never skips a character to search for a later key.
            break

    if len(output) > MAX_OUTPUT_BYTES:
        return None
    return bytes(output)


def expected_output(
    values: Sequence[int],
    capacity: int | None = None,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    """Return ``(status, bytes)`` for the packed translator ABI.

    Input validation takes precedence over output-pointer and capacity errors.
    """
    output = _translate(values)
    if output is None:
        return INVALID_RESULT, b""
    if (type(output_is_null) is not bool
            or (capacity is not None and (type(capacity) is not int or capacity < 0))):
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and len(output) > capacity):
        return OUTPUT_ERROR, b""
    return len(output), output

