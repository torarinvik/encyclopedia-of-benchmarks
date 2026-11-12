"""Independent arbitrary-precision verifier for signed decimal addition."""

from __future__ import annotations

MAX_DIGITS = 32
MAX_TEXT_LENGTH = 33
MAX_INPUT_LENGTH = 68
MAX_OUTPUT_BYTES = 34


def _parse_signed_text(text: tuple[int, ...]) -> int | None:
    if not 1 <= len(text) <= MAX_TEXT_LENGTH:
        return None
    negative = text[0] == 45
    offset = int(negative)
    digits = text[offset:]
    if (not digits or len(digits) > MAX_DIGITS
            or any(byte < 48 or byte > 57 for byte in digits)
            or (len(digits) > 1 and digits[0] == 48)
            or (negative and digits == (48,))):
        return None
    magnitude = int(bytes(digits).decode("ascii"))
    return -magnitude if negative else magnitude


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Use Python's integer parser and addition, independent of digit loops."""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if (len(values) < 4 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or value < -(1 << 63) or value >= 1 << 63
                   for value in values)):
        return -1, b""
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return -1, b""
    len_a, len_b = values[:2]
    if (type(len_a) is not int or type(len_b) is not int
            or not 1 <= len_a <= MAX_TEXT_LENGTH
            or not 1 <= len_b <= MAX_TEXT_LENGTH
            or len(values) != 2 + len_a + len_b):
        return -1, b""
    text_a = tuple(values[2:2 + len_a])
    text_b = tuple(values[2 + len_a:])
    if any(not 0 <= byte <= 127 for byte in text_a + text_b):
        return -1, b""
    number_a = _parse_signed_text(text_a)
    number_b = _parse_signed_text(text_b)
    if number_a is None or number_b is None:
        return -1, b""
    encoded = str(number_a + number_b).encode("ascii")
    if len(encoded) > MAX_OUTPUT_BYTES:
        return -1, b""
    if type(output_is_null) is not bool:
        return -2, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return -2, b""
    if output_is_null or (output_capacity is not None and len(encoded) > output_capacity):
        return -2, b""
    return len(encoded), encoded


def validate_output(values, output: bytes, **options) -> bool:
    status, expected = expected_output(values, **options)
    return status >= 0 and len(output) == status and output == expected
