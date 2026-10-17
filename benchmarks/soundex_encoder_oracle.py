"""Oracle for the iterator-safe bounded C# Soundex encoder slice."""

from __future__ import annotations

from collections.abc import Sequence

MAX_TEXT_LENGTH = 64
MAX_INPUT_LENGTH = MAX_TEXT_LENGTH + 1  # text length prefix plus ASCII codes
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 2
MAX_OUTPUT_BYTES = 4
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2

_GROUPS = {
    **{letter: 0 for letter in "aeiouy"},
    **{letter: 8 for letter in "hw"},
    **{letter: 1 for letter in "bfpv"},
    **{letter: 2 for letter in "cgjkqsxz"},
    **{letter: 3 for letter in "dt"},
    "l": 4,
    **{letter: 5 for letter in "mn"},
    "r": 6,
}


def expected_output(
    values: Sequence[int],
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the ABI status and four-byte Soundex code for ASCII letters."""
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
            or (input_is_null and len(values) != 0)
            or (not input_is_null and declared_length != len(values))
            or declared_length > MAX_PARSEABLE_INPUT_LENGTH):
        return INVALID_RESULT, b""
    if input_is_null or declared_length < 1 or declared_length > MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT, b""
    text_length = values[0]
    if (text_length < 1 or text_length > MAX_TEXT_LENGTH
            or declared_length != text_length + 1 or declared_length > MAX_INPUT_LENGTH):
        return INVALID_RESULT, b""
    text_values = values[1:]
    if any(not (65 <= value <= 90 or 97 <= value <= 122) for value in text_values):
        return INVALID_RESULT, b""

    lowercase = [value + 32 if 65 <= value <= 90 else value for value in text_values]
    collapsed: list[int] = []
    for value in lowercase:
        char = chr(value)
        if char in "hw":
            continue
        digit = _GROUPS[char]
        if not collapsed or collapsed[-1] != digit:
            collapsed.append(digit)

    # The source collapses adjacent mapped codes before removing vowel zeroes.
    codes = [digit for digit in collapsed if digit != 0]
    if not codes:
        return INVALID_RESULT, b""

    first_digit = _GROUPS[chr(lowercase[0])]
    if codes[0] == first_digit:
        # The pinned iterator advances once, then reads Current unconditionally.
        # Its call fails if that advance has no next element; exclude that edge.
        if len(codes) == 1:
            return INVALID_RESULT, b""
        codes = codes[1:]

    encoded = bytearray([lowercase[0] - 32 if 97 <= lowercase[0] <= 122 else lowercase[0]])
    for index in range(3):
        digit = codes[index] if index < len(codes) else 0
        encoded.append(ord("0") + digit)

    if (type(output_is_null) is not bool
            or (output_capacity is not None
                and (type(output_capacity) is not int or output_capacity < 0))):
        return INVALID_RESULT, b""
    if output_is_null or (output_capacity is not None and output_capacity < MAX_OUTPUT_BYTES):
        return OUTPUT_ERROR, b""
    return MAX_OUTPUT_BYTES, bytes(encoded)
