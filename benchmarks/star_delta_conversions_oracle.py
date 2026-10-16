"""Bounded real-impedance contract for the pinned star/delta formulas."""
from __future__ import annotations

MAX_INPUT_LENGTH = 4
INVALID_RESULT = -1
MASK64 = (1 << 64) - 1
FNV_OFFSET = 0xCBF29CE484222325
FNV_PRIME = 0x100000001B3


def expected_result(values: list[int]) -> int:
    if len(values) != MAX_INPUT_LENGTH:
        return INVALID_RESULT
    operation, a_i, b_i, c_i = values
    if operation not in (0, 1) or any(x < 1_000 or x > 100_000 for x in (a_i, b_i, c_i)):
        return INVALID_RESULT
    a, b, c = float(a_i), float(b_i), float(c_i)
    if operation == 0:
        pair_sum = a * b + b * c + c * a
        result = (pair_sum / a, pair_sum / b, pair_sum / c)
    else:
        total = a + b + c
        result = (b * c / total, c * a / total, a * b / total)
    quantized = [int(x + 0.5) for x in result]
    h = FNV_OFFSET
    for value in quantized:
        for byte in value.to_bytes(8, "little", signed=True):
            h = ((h ^ byte) * FNV_PRIME) & MASK64
    return h if h < (1 << 63) else h - (1 << 64)
