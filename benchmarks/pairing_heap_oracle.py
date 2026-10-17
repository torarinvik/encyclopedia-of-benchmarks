"""Independent oracle for the bounded ascending pairing-heap contract."""

from __future__ import annotations

from typing import Sequence

MAX_ITEMS = 128
MAX_INPUT_LENGTH = MAX_ITEMS + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MIN_I32 = -(2**31)
MAX_I32 = 2**31 - 1
FNV_OFFSET_BASIS = 14695981039346656037
FNV_PRIME = 1099511628211
MASK_64 = (1 << 64) - 1
MASK_63 = (1 << 63) - 1


def expected_result(values: Sequence[int]) -> int:
    """Return the low-63-bit extraction hash, or -1 when input is invalid."""
    if (
        not isinstance(values, (list, tuple))
        or len(values) < 1
        or len(values) > MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)
    ):
        return -1

    count = values[0]
    if not 2 <= count <= MAX_ITEMS or len(values) != count + 1:
        return -1
    keys = values[1:]
    if any(not MIN_I32 <= key <= MAX_I32 for key in keys):
        return -1
    if len(set(keys)) != count:
        return -1

    result = FNV_OFFSET_BASIS
    for key in sorted(keys)[:-1]:
        bits = key & 0xFFFFFFFF
        for shift in range(0, 32, 8):
            result = ((result ^ ((bits >> shift) & 0xFF)) * FNV_PRIME) & MASK_64
    return result & MASK_63
