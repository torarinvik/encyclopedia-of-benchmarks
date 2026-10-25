"""Independent SHA-0 oracle for the bounded MiBench single-block profile."""

from __future__ import annotations

from collections.abc import Sequence

MAX_MESSAGE_BYTES = 55
MAX_VALID_INPUT_LENGTH = MAX_MESSAGE_BYTES + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
OUTPUT_BYTES = 20
INVALID_RESULT = -1
OUTPUT_ERROR = -2
MASK32 = 0xFFFFFFFF

_INITIAL_STATE = (0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0)
_ROUND_CONSTANTS = (0x5A827999, 0x6ED9EBA1, 0x8F1BBCDC, 0xCA62C1D6)


def _rotate_left(value: int, count: int) -> int:
    value &= MASK32
    return ((value << count) | (value >> (32 - count))) & MASK32


def _digest(message: bytes) -> bytes:
    # SHA-0 has a single 512-bit block for up to 55 input bytes.
    block = bytearray(64)
    block[:len(message)] = message
    block[len(message)] = 0x80
    block[56:64] = (len(message) * 8).to_bytes(8, "big")

    words = [int.from_bytes(block[offset:offset + 4], "big") for offset in range(0, 64, 4)]
    for index in range(16, 80):
        # Unlike SHA-1, SHA-0 does not rotate the expanded XOR word.
        words.append(words[index - 3] ^ words[index - 8] ^ words[index - 14] ^ words[index - 16])

    a, b, c, d, e = _INITIAL_STATE
    for index, word in enumerate(words):
        if index < 20:
            function, constant = (b & c) | ((~b) & d), _ROUND_CONSTANTS[0]
        elif index < 40:
            function, constant = b ^ c ^ d, _ROUND_CONSTANTS[1]
        elif index < 60:
            function, constant = (b & c) | (b & d) | (c & d), _ROUND_CONSTANTS[2]
        else:
            function, constant = b ^ c ^ d, _ROUND_CONSTANTS[3]
        temporary = (_rotate_left(a, 5) + function + e + word + constant) & MASK32
        a, b, c, d, e = temporary, a, _rotate_left(b, 30), c, d

    state = [(_INITIAL_STATE[i] + value) & MASK32 for i, value in enumerate((a, b, c, d, e))]
    return b"".join(value.to_bytes(4, "big") for value in state)


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = OUTPUT_BYTES,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if values is None:
        values = ()
    if input_is_null:
        return INVALID_RESULT, b""
    if (not isinstance(values, (list, tuple))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)):
        return INVALID_RESULT, b""
    actual_length = len(values) if input_length is None else input_length
    if (type(actual_length) is not int or actual_length < 1
            or actual_length > MAX_PARSEABLE_INPUT_LENGTH or len(values) != actual_length):
        return INVALID_RESULT, b""
    raw = values
    message_length = raw[0]
    if (not 0 <= message_length <= MAX_MESSAGE_BYTES
            or actual_length != message_length + 1
            or any(not 0 <= value <= 255 for value in raw[1:])):
        return INVALID_RESULT, b""
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < OUTPUT_BYTES)):
        return OUTPUT_ERROR, b""
    return OUTPUT_BYTES, _digest(bytes(raw[1:]))
