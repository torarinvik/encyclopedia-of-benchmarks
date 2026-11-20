"""Packed-word reference for the bounded repeated bitset shift-XOR trace."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_BITS = 4096
MAX_OPERATIONS = 64
MAX_WORDS = 64
MAX_VALID_INPUT_LENGTH = 130
MAX_PARSEABLE_INPUT_LENGTH = 131
MAX_OUTPUT_BYTES = 256
WORKSPACE_BYTES = 1024
MASK64 = (1 << 64) - 1


def _parse(values: Sequence[int] | None, input_length: int | None):
    if (not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return None
    bit_count, operation_count = values[:2]
    if not 1 <= bit_count <= MAX_BITS or not 0 <= operation_count <= MAX_OPERATIONS:
        return None
    word_count = (bit_count + 63) // 64
    if input_length != 2 + word_count + operation_count:
        return None
    words = [value & MASK64 for value in values[2:2 + word_count]]
    top_bits = bit_count & 63
    if top_bits and words[-1] >> top_bits:
        return None
    shifts = values[2 + word_count:]
    if any(not -(bit_count - 1) <= shift <= bit_count - 1 for shift in shifts):
        return None
    return bit_count, words, shifts


def _run(bit_count: int, words: list[int], shifts: Sequence[int]) -> bytes:
    word_count = len(words)
    top_bits = bit_count & 63
    top_mask = (1 << top_bits) - 1 if top_bits else MASK64
    counts: list[int] = []
    for shift in shifts:
        if shift == 0:
            for index in range(word_count):
                words[index] = 0
        elif shift > 0:
            whole, part = divmod(shift, 64)
            for destination in range(word_count):
                source = destination + whole
                shifted = words[source] >> part if source < word_count else 0
                if part and source + 1 < word_count:
                    shifted |= (words[source + 1] << (64 - part)) & MASK64
                words[destination] ^= shifted
        else:
            distance = -shift
            whole, part = divmod(distance, 64)
            for destination in range(word_count - 1, -1, -1):
                source = destination - whole
                shifted = (words[source] << part) & MASK64 if source >= 0 else 0
                if part and source > 0:
                    shifted |= words[source - 1] >> (64 - part)
                words[destination] ^= shifted
        words[-1] &= top_mask
        counts.append(sum(word.bit_count() for word in words))
    return b"".join(struct.pack("<i", count) for count in counts)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or (capacity is not None and (type(capacity) is not int or capacity < 0))):
        return -1, b""
    if type(input_is_null) is not bool or input_is_null:
        return -1, b""
    if input_length is not None and (type(input_length) is not int
                                     or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH):
        return -1, b""
    parsed = _parse(values, input_length)
    if parsed is None:
        return -1, b""
    bit_count, words, shifts = parsed
    payload = _run(bit_count, words, shifts)
    if len(payload) > MAX_OUTPUT_BYTES:
        return -1, b""
    if payload and (output_is_null or (capacity is not None and capacity < len(payload))):
        return -2, b""
    return len(payload), payload
