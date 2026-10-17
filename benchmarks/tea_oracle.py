"""Independent oracle for a bounded single-block TEA operation."""

from __future__ import annotations

import struct
from collections.abc import Sequence

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
MAX_VALID_INPUT_LENGTH = 6
MAX_PARSEABLE_INPUT_LENGTH = 7
MAX_OUTPUT_BYTES = 16
MASK32 = (1 << 32) - 1
DELTA = 0x9E3779B9
DECRYPT_SUM = 0xC6EF3720
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2


def _combine_words(low: int, high: int) -> int:
    return (low & MASK32) | ((high & MASK32) << 32)


def _split_words(value: int) -> tuple[int, int]:
    return value & MASK32, (value >> 32) & MASK32


def _encrypt(block: int, key0: int, key1: int) -> int:
    b0, b1 = _split_words(block)
    k0, k1 = _split_words(key0)
    k2, k3 = _split_words(key1)
    total = 0
    for _ in range(32):
        total = (total + DELTA) & MASK32
        mix0 = ((((b1 << 4) & MASK32) + k0) & MASK32) ^ ((b1 + total) & MASK32) ^ (((b1 >> 5) + k1) & MASK32)
        b0 = (b0 + mix0) & MASK32
        mix1 = ((((b0 << 4) & MASK32) + k2) & MASK32) ^ ((b0 + total) & MASK32) ^ (((b0 >> 5) + k3) & MASK32)
        b1 = (b1 + mix1) & MASK32
    return (b1 << 32) | b0


def _decrypt(block: int, key0: int, key1: int) -> int:
    b0, b1 = _split_words(block)
    k0, k1 = _split_words(key0)
    k2, k3 = _split_words(key1)
    total = DECRYPT_SUM
    for _ in range(32):
        mix1 = ((((b0 << 4) & MASK32) + k2) & MASK32) ^ ((b0 + total) & MASK32) ^ (((b0 >> 5) + k3) & MASK32)
        b1 = (b1 - mix1) & MASK32
        mix0 = ((((b1 << 4) & MASK32) + k0) & MASK32) ^ ((b1 + total) & MASK32) ^ (((b1 >> 5) + k1) & MASK32)
        b0 = (b0 - mix0) & MASK32
        total = (total - DELTA) & MASK32
    return (b1 << 32) | b0


def expected_output(
    values: Sequence[int],
    output_capacity: int = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
    input_is_null: bool = False,
) -> tuple[int, bytes]:
    """Return encrypted and recovered u64 values in little-endian order."""
    if type(input_is_null) is not bool or type(output_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null:
        return INVALID_RESULT, b""
    if (
        not isinstance(values, (list, tuple))
        or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
        or len(values) != MAX_VALID_INPUT_LENGTH
        or any(not I32_MIN <= value <= I32_MAX for value in values)
    ):
        return INVALID_RESULT, b""
    if type(output_capacity) is not int or output_capacity < 0:
        return INVALID_RESULT, b""

    block = _combine_words(values[0], values[1])
    key0 = _combine_words(values[2], values[3])
    key1 = _combine_words(values[4], values[5])
    ciphertext = _encrypt(block, key0, key1)
    recovered = _decrypt(ciphertext, key0, key1)
    output = struct.pack("<QQ", ciphertext, recovered)
    if output_is_null or output_capacity < len(output):
        return OUTPUT_ERROR_RESULT, b""
    return len(output), output
