"""Oracle for the bounded Java monoalphabetic substitution cipher."""

from __future__ import annotations

from collections.abc import Sequence

MAX_TEXT_LENGTH = 256
MAX_VALID_INPUT_LENGTH = 28 + MAX_TEXT_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
FNV_OFFSET_BASIS = 14695981039346656037
FNV_PRIME = 1099511628211
MASK64 = (1 << 64) - 1
MASK63 = (1 << 63) - 1
INVALID_RESULT = -1


def _feed_byte(value: int, byte: int) -> int:
    return ((value ^ byte) * FNV_PRIME) & MASK64


def _output_hash(output: bytes) -> int:
    """Hash u64le(output length), then output bytes; return the low 63 bits."""
    value = FNV_OFFSET_BASIS
    for byte in len(output).to_bytes(8, "little", signed=False):
        value = _feed_byte(value, byte)
    for byte in output:
        value = _feed_byte(value, byte)
    return value & MASK63


def expected_output(
    values: Sequence[int] | None,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    """Return the scalar cipher digest, or -1 for invalid input."""
    if type(input_is_null) is not bool:
        return INVALID_RESULT
    if input_length is not None and (
        type(input_length) is not int or input_length < 0
    ):
        return INVALID_RESULT
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT
    if not 29 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT

    operation, text_length = values[0], values[1]
    if operation not in (0, 1) or not 1 <= text_length <= MAX_TEXT_LENGTH:
        return INVALID_RESULT
    if len(values) != 28 + text_length:
        return INVALID_RESULT

    key = values[2:28]
    if any(not 65 <= value <= 90 for value in key):
        return INVALID_RESULT
    if len(set(key)) != 26:
        return INVALID_RESULT
    text = values[28:]
    if any(not 65 <= value <= 90 for value in text):
        return INVALID_RESULT

    inverse = [0] * 26
    for index, value in enumerate(key):
        inverse[value - 65] = index
    if operation == 0:
        output = bytes(key[value - 65] for value in text)
    else:
        output = bytes(65 + inverse[value - 65] for value in text)
    return _output_hash(output)
