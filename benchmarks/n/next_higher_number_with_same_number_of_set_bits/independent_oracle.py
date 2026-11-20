"""Bit-string reference that relocates the rightmost movable one-run."""

from __future__ import annotations

MIN_INPUT = 1
MAX_INPUT = (1 << 30) - 1
MAX_RESULT = 1_610_612_735
INVALID_RESULT = -1


def expected_result(value: int) -> int:
    if type(value) is not int or not MIN_INPUT <= value <= MAX_INPUT:
        return INVALID_RESULT

    bits = format(value, "b")
    trailing_zeroes = 0
    for bit in reversed(bits):
        if bit != "0":
            break
        trailing_zeroes += 1

    trailing_ones = 0
    for bit in reversed(bits[:len(bits) - trailing_zeroes]):
        if bit != "1":
            break
        trailing_ones += 1

    pivot_from_right = trailing_zeroes + trailing_ones
    prefix_length = max(0, len(bits) - pivot_from_right - 1)
    prefix = bits[:prefix_length]
    zeroes_after_pivot = pivot_from_right - trailing_ones + 1
    compacted_ones = trailing_ones - 1
    successor_bits = prefix + "1" + ("0" * zeroes_after_pivot) + ("1" * compacted_ones)
    result = int(successor_bits, 2)
    return result if result <= MAX_RESULT else INVALID_RESULT
