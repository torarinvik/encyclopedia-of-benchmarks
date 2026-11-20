"""Streaming-word MD4 oracle from the published RFC algorithm description."""

from __future__ import annotations

from collections.abc import Sequence

MAX_MESSAGE_BYTES = 4096
MAX_VALID_INPUT_LENGTH = MAX_MESSAGE_BYTES + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 16
WORKSPACE_BYTES = 512
INVALID_RESULT = -1
OUTPUT_ERROR = -2
_MASK = 0xFFFF_FFFF
_INITIAL = (0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476)
_ROUND3_ORDER = (0, 8, 4, 12, 2, 10, 6, 14, 1, 9, 5, 13, 3, 11, 7, 15)


def _rol(value: int, shift: int) -> int:
    return ((value << shift) | (value >> (32 - shift))) & _MASK


def _f(x: int, y: int, z: int) -> int:
    return (x & y) | (~x & z)


def _g(x: int, y: int, z: int) -> int:
    return (x & y) | (x & z) | (y & z)


def _h(x: int, y: int, z: int) -> int:
    return x ^ y ^ z


def _compress(state: tuple[int, int, int, int], words: Sequence[int]) -> tuple[int, int, int, int]:
    a, b, c, d = state
    saved_a, saved_b, saved_c, saved_d = state
    for step in range(48):
        phase, index = divmod(step, 16)
        operation = index & 3
        if operation == 0:
            target, left, middle, right = 0, b, c, d
        elif operation == 1:
            target, left, middle, right = 3, a, b, c
        elif operation == 2:
            target, left, middle, right = 2, d, a, b
        else:
            target, left, middle, right = 1, c, d, a
        if phase == 0:
            function, word_index = _f(left, middle, right), index
            shift = (3, 7, 11, 19)[index & 3]
            constant = 0
        elif phase == 1:
            function = _g(left, middle, right)
            word_index = (index & 3) * 4 + index // 4
            shift = (3, 5, 9, 13)[index & 3]
            constant = 0x5A827999
        else:
            function = _h(left, middle, right)
            word_index = _ROUND3_ORDER[index]
            shift = (3, 9, 11, 15)[index & 3]
            constant = 0x6ED9EBA1

        addend = (a, b, c, d)[target]
        total = (addend + function + words[word_index] + constant) & _MASK
        rotated = _rol(total, shift)
        if target == 0:
            a = rotated
        elif target == 1:
            b = rotated
        elif target == 2:
            c = rotated
        else:
            d = rotated
    return (
        (saved_a + a) & _MASK,
        (saved_b + b) & _MASK,
        (saved_c + c) & _MASK,
        (saved_d + d) & _MASK,
    )


def _message_word(message: Sequence[int], block_offset: int, word_index: int,
                  padded_length: int, bit_length: int) -> int:
    word = 0
    start = block_offset + 4 * word_index
    for byte_offset in range(4):
        position = start + byte_offset
        if position < len(message):
            value = message[position]
        elif position == len(message):
            value = 0x80
        elif position >= padded_length - 8:
            value = (bit_length >> (8 * (position - (padded_length - 8)))) & 0xFF
        else:
            value = 0
        word |= value << (8 * byte_offset)
    return word


def _digest(message: Sequence[int]) -> bytes:
    length = len(message)
    padded_length = ((length + 8) // 64 + 1) * 64
    bit_length = length * 8
    state = _INITIAL
    for offset in range(0, padded_length, 64):
        words = tuple(_message_word(message, offset, index, padded_length, bit_length)
                      for index in range(16))
        state = _compress(state, words)
    return b"".join(word.to_bytes(4, "little") for word in state)


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the digest or the documented byte-output ABI status."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return INVALID_RESULT, b""
    if input_length is not None and (type(input_length) is not int or input_length < 0):
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    if (not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT, b""
    declared = values[0]
    if type(declared) is not int or not 0 <= declared <= MAX_MESSAGE_BYTES:
        return INVALID_RESULT, b""
    if len(values) != declared + 1:
        return INVALID_RESULT, b""
    message = values[1:]
    if any(not 0 <= byte <= 255 for byte in message):
        return INVALID_RESULT, b""
    if output_is_null or (output_capacity is not None and output_capacity < MAX_OUTPUT_BYTES):
        return OUTPUT_ERROR, b""
    return MAX_OUTPUT_BYTES, _digest(message)
