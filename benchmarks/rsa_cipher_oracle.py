"""Oracle for one bounded ASCII character through the pinned RSA cipher."""

from __future__ import annotations

from collections.abc import Sequence

MIN_ASCII_CODE = 0
MAX_ASCII_CODE = 127
MIN_MODULUS = 128
MAX_MODULUS = 65_535
MAX_EXPONENT = MAX_MODULUS - 1
MAX_VALID_INPUT_VALUES = 3
MAX_PARSEABLE_INPUT_VALUES = MAX_VALID_INPUT_VALUES + 1
INVALID_RESULT = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _decode_input(values: Sequence[int] | None):
    if (
        not isinstance(values, (list, tuple))
        or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_VALUES
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return None
    if len(values) != MAX_VALID_INPUT_VALUES:
        return None

    ascii_code, exponent, modulus = values
    if not MIN_ASCII_CODE <= ascii_code <= MAX_ASCII_CODE:
        return None
    if not MIN_MODULUS <= modulus <= MAX_MODULUS:
        return None
    if not 1 <= exponent < modulus or exponent > MAX_EXPONENT:
        return None
    return ascii_code, exponent, modulus


def expected_result(
    values: Sequence[int] | None,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    """Return the RSA ciphertext for one ASCII code, or -1 for invalid input."""
    if type(input_is_null) is not bool:
        return INVALID_RESULT
    if input_length is not None and (type(input_length) is not int or input_length < 0):
        return INVALID_RESULT
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT
    decoded = _decode_input(values)
    if decoded is None:
        return INVALID_RESULT
    ascii_code, exponent, modulus = decoded
    return pow(ascii_code, exponent, modulus)
