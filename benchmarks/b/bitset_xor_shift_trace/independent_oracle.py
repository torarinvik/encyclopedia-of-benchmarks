"""Bit-by-bit reference for the bounded repeated bitset shift-XOR trace."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_BITS = 4096
MAX_OPERATIONS = 64
MAX_PARSEABLE_INPUT_LENGTH = 131
MAX_OUTPUT_BYTES = 256
WORKSPACE_BYTES = 1024
MASK64 = (1 << 64) - 1


def _decode(values: Sequence[int] | None, input_length: int | None):
    if not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    declared = len(values) if input_length is None else input_length
    if type(declared) is not int or declared != len(values):
        return None
    n, q = values[0], values[1]
    if not 1 <= n <= MAX_BITS or not 0 <= q <= MAX_OPERATIONS:
        return None
    word_count = (n + 63) // 64
    if declared != 2 + word_count + q:
        return None
    packed = values[2:2 + word_count]
    last_width = n % 64
    if last_width and ((packed[-1] & MASK64) >> last_width):
        return None
    moves = values[2 + word_count:]
    if any(move < -(n - 1) or move > n - 1 for move in moves):
        return None
    bits = [((packed[position // 64] & MASK64) >> (position % 64)) & 1
            for position in range(n)]
    return bits, moves


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or (capacity is not None and (type(capacity) is not int or capacity < 0))):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    if input_length is not None and (type(input_length) is not int
                                     or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH):
        return -1, b""
    parsed = _decode(values, input_length)
    if parsed is None:
        return -1, b""
    bits, shifts = parsed
    counts: list[int] = []
    n = len(bits)
    for shift in shifts:
        previous = bits
        if shift == 0:
            bits = [0] * n
        elif shift > 0:
            bits = [previous[index] ^ (previous[index + shift] if index + shift < n else 0)
                    for index in range(n)]
        else:
            distance = -shift
            bits = [previous[index] ^ (previous[index - distance] if index >= distance else 0)
                    for index in range(n)]
        counts.append(sum(bits))
    payload = b"".join(struct.pack("<i", count) for count in counts)
    if len(payload) > MAX_OUTPUT_BYTES:
        return -1, b""
    if payload and (output_is_null or (capacity is not None and capacity < len(payload))):
        return -2, b""
    return len(payload), payload
