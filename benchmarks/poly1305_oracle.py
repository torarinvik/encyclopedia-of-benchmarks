"""Bounded mathematical oracle for the pinned Poly1305 implementation."""

from __future__ import annotations

from collections.abc import Sequence

MIN_MESSAGE_LENGTH = 0
MAX_MESSAGE_LENGTH = 64
KEY_LENGTH = 32
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_VALID_INPUT_LENGTH = 1 + KEY_LENGTH + MAX_MESSAGE_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_PARSEABLE_INPUT_VALUES = MAX_PARSEABLE_INPUT_LENGTH
MAX_OUTPUT_BYTES = 16
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2
R_MASK = int("0ffffffc0ffffffc0ffffffc0fffffff", 16)
MODULUS = (1 << 130) - 5
MASK_128 = (1 << 128) - 1


def expected_output(
    values: Sequence[int],
    output_capacity: int = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
    input_is_null: bool = False,
) -> tuple[int, bytes]:
    """Return (bytes written/error, 16-byte little-endian Poly1305 tag)."""
    if type(input_is_null) is not bool or type(output_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null:
        return INVALID_RESULT, b""
    if (
        not isinstance(values, (list, tuple))
        or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return INVALID_RESULT, b""

    message_length = values[0]
    if not MIN_MESSAGE_LENGTH <= message_length <= MAX_MESSAGE_LENGTH:
        return INVALID_RESULT, b""
    if len(values) != 1 + KEY_LENGTH + message_length:
        return INVALID_RESULT, b""
    key = values[1 : 1 + KEY_LENGTH]
    message = values[1 + KEY_LENGTH :]
    if any(not 0 <= byte <= 255 for byte in (*key, *message)):
        return INVALID_RESULT, b""
    if type(output_capacity) is not int or output_capacity < 0:
        return INVALID_RESULT, b""

    r = int.from_bytes(bytes(key[:16]), "little") & R_MASK
    s = int.from_bytes(bytes(key[16:]), "little")
    accumulator = 0
    message_bytes = bytes(message)
    for offset in range(0, message_length, 16):
        block = message_bytes[offset : offset + 16]
        number = int.from_bytes(block, "little") + (1 << (8 * len(block)))
        accumulator = ((accumulator + number) * r) % MODULUS
    tag = ((accumulator + s) & MASK_128).to_bytes(16, "little")
    if output_is_null or output_capacity < MAX_OUTPUT_BYTES:
        return OUTPUT_ERROR_RESULT, b""
    return MAX_OUTPUT_BYTES, tag
