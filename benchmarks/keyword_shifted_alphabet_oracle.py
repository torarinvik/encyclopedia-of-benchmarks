"""Bounded byte reference for the pinned JavaScript keyword alphabet cipher."""

from __future__ import annotations

MAX_KEYWORD_LENGTH = 26
MAX_MESSAGE_LENGTH = 512
MAX_INPUT_LENGTH = MAX_KEYWORD_LENGTH + MAX_MESSAGE_LENGTH + 4
MAX_OUTPUT_BYTES = MAX_MESSAGE_LENGTH
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY_RESULT = -2
I64_MIN, I64_MAX = -(1 << 63), (1 << 63) - 1
ALPHABET = b"abcdefghijklmnopqrstuvwxyz"


def expected_output(values: list[int] | tuple[int, ...],
                    output_capacity: int | None = None) -> tuple[int, bytes]:
    """Return the encoded/decoded ASCII message bytes, or an ABI status."""
    if (not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT, b""
    operation, keyword_length, message_length = values[:3]
    if (operation not in (0, 1) or not 1 <= keyword_length <= MAX_KEYWORD_LENGTH
            or not 1 <= message_length <= MAX_MESSAGE_LENGTH
            or len(values) != 3 + keyword_length + message_length):
        return INVALID_RESULT, b""
    keyword = values[3:3 + keyword_length]
    message = values[3 + keyword_length:]
    if (any(not (65 <= value <= 90 or 97 <= value <= 122) for value in keyword)
            or any(not 0 <= value <= 127 for value in message)):
        return INVALID_RESULT, b""
    normalized = bytes(value + 32 if 65 <= value <= 90 else value for value in keyword)
    if len(set(normalized)) != len(normalized):
        return INVALID_RESULT, b""
    cipher_alphabet = normalized + bytes(letter for letter in ALPHABET if letter not in normalized)
    decode = {letter: ALPHABET[index] for index, letter in enumerate(cipher_alphabet)}
    output = bytearray()
    for value in message:
        upper = 65 <= value <= 90
        lower = value + 32 if upper else value
        if 97 <= lower <= 122:
            encoded = (cipher_alphabet[lower - 97] if operation == 0
                       else decode[lower])
            output.append(encoded - 32 if upper else encoded)
        else:
            output.append(value)
    if output_capacity is not None:
        if type(output_capacity) is not int or output_capacity < 0:
            return INVALID_RESULT, b""
        if output_capacity < len(output):
            return INSUFFICIENT_CAPACITY_RESULT, b""
    return len(output), bytes(output)
