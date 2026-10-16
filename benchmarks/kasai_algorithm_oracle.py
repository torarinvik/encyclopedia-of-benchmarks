"""Oracle for the bounded Kasai LCP-array benchmark."""

from __future__ import annotations

MAX_LENGTH = 512
MAX_INPUT_LENGTH = 1 + 2 * MAX_LENGTH
MIN_I64 = -(1 << 63)
MAX_I64 = (1 << 63) - 1
FNV_OFFSET_BASIS = 14695981039346656037
FNV_PRIME = 1099511628211
MASK_64 = (1 << 64) - 1
MASK_63 = (1 << 63) - 1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Return the low-63-bit LCP checksum, or -1 when the packed input is invalid."""
    if not isinstance(values, (list, tuple)) or not values:
        return -1
    if any(type(value) is not int or not MIN_I64 <= value <= MAX_I64 for value in values):
        return -1

    n = values[0]
    if n < 0 or n > MAX_LENGTH or len(values) != 1 + 2 * n:
        return -1
    text_values = values[1 : 1 + n]
    if any(byte < 0 or byte > 127 for byte in text_values):
        return -1
    suffix_array = list(values[1 + n :])
    if sorted(suffix_array) != list(range(n)):
        return -1

    text = bytes(text_values)
    if any(text[suffix_array[i - 1] :] >= text[suffix_array[i] :] for i in range(1, n)):
        return -1

    rank = [0] * n
    for position, suffix in enumerate(suffix_array):
        rank[suffix] = position
    lcp = [0] * n
    common = 0
    for start in range(n):
        current_rank = rank[start]
        if current_rank == n - 1:
            common = 0
            continue
        next_start = suffix_array[current_rank + 1]
        while start + common < n and next_start + common < n and text[start + common] == text[next_start + common]:
            common += 1
        lcp[current_rank] = common
        if common > 0:
            common -= 1

    result = FNV_OFFSET_BASIS
    for word in [n, *lcp]:
        bits = word & MASK_64
        for shift in range(0, 64, 8):
            result ^= (bits >> shift) & 0xFF
            result = (result * FNV_PRIME) & MASK_64
    return result & MASK_63
