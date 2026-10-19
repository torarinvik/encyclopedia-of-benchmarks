"""Bounded oracle for the classic Benchmark Game packed-bit sieve."""

from __future__ import annotations

import struct
from typing import Sequence

MAX_LIMIT = 1_000_000
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
MAX_OUTPUT_BYTES = 24
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _count_primes(limit: int) -> int:
    # The upstream source starts every bit set and flips each still-set multiple
    # when it reaches its smallest prime factor.
    bits = [0xFFFF_FFFF_FFFF_FFFF] * (limit // 64 + 1)
    count = 0
    for value in range(2, limit + 1):
        mask = 1 << (value & 63)
        word = value >> 6
        if bits[word] & mask:
            count += 1
            for multiple in range(value + value, limit + 1, value):
                multiple_word = multiple >> 6
                multiple_mask = 1 << (multiple & 63)
                if bits[multiple_word] & multiple_mask:
                    bits[multiple_word] ^= multiple_mask
    return count


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or (output_capacity is not None
                and (type(output_capacity) is not int or output_capacity < 0))
            or (input_length is not None
                and (type(input_length) is not int or input_length < 0))):
        return INVALID_RESULT, b""
    if (input_is_null or values is None or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None and input_length != len(values))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT, b""
    if len(values) != 1 or not 0 <= values[0] <= MAX_LIMIT:
        return INVALID_RESULT, b""
    if output_is_null or (output_capacity is not None and output_capacity < MAX_OUTPUT_BYTES):
        return OUTPUT_ERROR, b""
    limit = values[0]
    counts = (_count_primes(limit), _count_primes(limit >> 1), _count_primes(limit >> 2))
    return MAX_OUTPUT_BYTES, struct.pack("<3Q", *counts)
