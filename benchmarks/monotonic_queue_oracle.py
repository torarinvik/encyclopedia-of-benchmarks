"""Independent direct-window oracle for sliding-window maxima."""

from __future__ import annotations

MAX_COUNT = 4096
MAX_INPUT_LENGTH = MAX_COUNT + 2
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
FNV_OFFSET = 14695981039346656037
FNV_PRIME = 1099511628211
MASK64 = (1 << 64) - 1
MASK63 = (1 << 63) - 1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1
    count, window = values[:2]
    if not 1 <= count <= MAX_COUNT or not 1 <= window <= count or len(values) != count + 2:
        return -1
    items = values[2:]
    if any(value < I32_MIN or value > I32_MAX for value in items):
        return -1
    result = [max(items[start:start + window]) for start in range(count - window + 1)]
    digest = FNV_OFFSET
    for value in result:
        bits = value & 0xFFFFFFFF
        for shift in (0, 8, 16, 24):
            digest = ((digest ^ ((bits >> shift) & 0xFF)) * FNV_PRIME) & MASK64
    return digest & MASK63
