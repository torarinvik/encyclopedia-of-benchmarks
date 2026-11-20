"""One-shot padded-message MD4 reference, separated from the streaming oracle."""

from __future__ import annotations

from collections.abc import Sequence

MAX_MESSAGE_BYTES = 4096
MAX_VALID_INPUT_LENGTH = MAX_MESSAGE_BYTES + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 16
INVALID_RESULT = -1
OUTPUT_ERROR = -2
_MASK = 0xFFFF_FFFF
_INITIAL = [0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476]
_R3 = (0, 8, 4, 12, 2, 10, 6, 14, 1, 9, 5, 13, 3, 11, 7, 15)


def _rotate(value: int, amount: int) -> int:
    value &= _MASK
    return ((value << amount) | (value >> (32 - amount))) & _MASK


def _f(x: int, y: int, z: int) -> int:
    return (x & y) | (~x & z)


def _g(x: int, y: int, z: int) -> int:
    return (x & y) | (x & z) | (y & z)


def _h(x: int, y: int, z: int) -> int:
    return x ^ y ^ z


def _one_shot_digest(data: bytes) -> bytes:
    padded = bytearray(data)
    padded.append(0x80)
    while len(padded) % 64 != 56:
        padded.append(0)
    padded.extend((len(data) * 8).to_bytes(8, "little"))
    state = _INITIAL.copy()

    for offset in range(0, len(padded), 64):
        block = padded[offset:offset + 64]
        words = [int.from_bytes(block[i:i + 4], "little") for i in range(0, 64, 4)]
        aa, bb, cc, dd = state
        a, b, c, d = state
        for round_index in range(3):
            for index in range(16):
                if round_index == 0:
                    function, word_index, shifts, constant = (
                        _f, index, (3, 7, 11, 19), 0
                    )
                elif round_index == 1:
                    function = _g
                    word_index = (index % 4) * 4 + index // 4
                    shifts, constant = (3, 5, 9, 13), 0x5A827999
                else:
                    function, word_index = _h, _R3[index]
                    shifts, constant = (3, 9, 11, 15), 0x6ED9EBA1
                result = (a + function(b, c, d) + words[word_index] + constant) & _MASK
                a = _rotate(result, shifts[index & 3])
                a, b, c, d = d, a, b, c
        state = [
            (aa + a) & _MASK,
            (bb + b) & _MASK,
            (cc + c) & _MASK,
            (dd + d) & _MASK,
        ]
    return b"".join(word.to_bytes(4, "little") for word in state)


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
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
    length = values[0]
    if type(length) is not int or not 0 <= length <= MAX_MESSAGE_BYTES:
        return INVALID_RESULT, b""
    if len(values) != length + 1:
        return INVALID_RESULT, b""
    data = values[1:]
    if any(not 0 <= byte <= 255 for byte in data):
        return INVALID_RESULT, b""
    if output_is_null or (output_capacity is not None and output_capacity < MAX_OUTPUT_BYTES):
        return OUTPUT_ERROR, b""
    return MAX_OUTPUT_BYTES, _one_shot_digest(bytes(data))
