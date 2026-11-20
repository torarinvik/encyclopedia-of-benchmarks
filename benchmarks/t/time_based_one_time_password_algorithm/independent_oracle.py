"""Independent fixed-block SHA-1/HMAC implementation of the TOTP profile."""

from __future__ import annotations

from collections.abc import Sequence

MAX_KEY_BYTES = 64
MAX_VALID_INPUT_LENGTH = 66
MAX_PARSEABLE_INPUT_LENGTH = 67
MAX_OUTPUT_BYTES = 6
WORKSPACE_BYTES = 1024
INVALID_RESULT = -1
OUTPUT_ERROR = -2
_MASK = 0xFFFFFFFF
_INITIAL = (0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0)


def _rol(value: int, shift: int) -> int:
    return ((value << shift) | (value >> (32 - shift))) & _MASK


def _compress(state: list[int], block: bytes) -> None:
    schedule = [0] * 80
    for index in range(16):
        start = 4 * index
        schedule[index] = int.from_bytes(block[start:start + 4], "big")
    for index in range(16, 80):
        schedule[index] = _rol(schedule[index - 3] ^ schedule[index - 8]
                               ^ schedule[index - 14] ^ schedule[index - 16], 1)
    a, b, c, d, e = state
    for index, word in enumerate(schedule):
        if index < 20:
            choose, constant = (b & c) | (~b & d), 0x5A827999
        elif index < 40:
            choose, constant = b ^ c ^ d, 0x6ED9EBA1
        elif index < 60:
            choose, constant = (b & c) | (b & d) | (c & d), 0x8F1BBCDC
        else:
            choose, constant = b ^ c ^ d, 0xCA62C1D6
        temp = (_rol(a, 5) + choose + e + constant + word) & _MASK
        a, b, c, d, e = temp, a, _rol(b, 30), c, d
    state[0] = (state[0] + a) & _MASK
    state[1] = (state[1] + b) & _MASK
    state[2] = (state[2] + c) & _MASK
    state[3] = (state[3] + d) & _MASK
    state[4] = (state[4] + e) & _MASK


def _one_sha1_block_after_prefix(prefix_block: bytes, tail: bytes,
                                 message_length: int) -> bytes:
    """Hash a 64-byte prefix followed by a short tail, using exactly two blocks."""
    state = list(_INITIAL)
    _compress(state, prefix_block)
    block = bytearray(64)
    block[:len(tail)] = tail
    block[len(tail)] = 0x80
    block[56:64] = (message_length * 8).to_bytes(8, "big")
    _compress(state, bytes(block))
    return b"".join(word.to_bytes(4, "big") for word in state)


def _totp(key: bytes, timestamp: int) -> bytes:
    normalized = key + bytes(64 - len(key))
    inner_prefix = bytes(value ^ 0x36 for value in normalized)
    outer_prefix = bytes(value ^ 0x5C for value in normalized)
    counter = (timestamp // 30).to_bytes(8, "big")
    inner = _one_sha1_block_after_prefix(inner_prefix, counter, 72)
    digest = _one_sha1_block_after_prefix(outer_prefix, inner, 84)
    offset = digest[19] & 15
    binary = int.from_bytes(digest[offset:offset + 4], "big") & 0x7FFFFFFF
    value = binary % 1_000_000
    chars = [48] * 6
    for place in range(5, -1, -1):
        chars[place] += value % 10
        value //= 10
    return bytes(chars)


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[bytes, int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    length = values[0]
    if not 16 <= length <= MAX_KEY_BYTES or len(values) != length + 2:
        return None
    key_part = values[1:length + 1]
    seconds = values[-1]
    if any(byte < 0 or byte > 255 for byte in key_part) or seconds < 0:
        return None
    return bytes(key_part), seconds


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and (not isinstance(values, (list, tuple)) or input_length != len(values))):
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    payload = _totp(*parsed)
    if output_is_null or capacity is not None and capacity < 6:
        return OUTPUT_ERROR, b""
    return 6, payload
