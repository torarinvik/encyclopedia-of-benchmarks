"""Bounded logical semantics shared by the two pinned Java chained maps."""
from __future__ import annotations

MAX_OPERATIONS = 128
MAX_INPUT_LENGTH = 1 + 3 * MAX_OPERATIONS
MAX_ENTRIES = 64
INVALID_RESULT = -1
MASK = (1 << 64) - 1
OFFSET = 0xCBF29CE484222325
PRIME = 0x100000001B3
I64_MIN = -(1 << 63)


def _hash_value(h: int, value: int) -> int:
    bits = value & MASK
    for shift in range(0, 64, 8):
        h = ((h ^ ((bits >> shift) & 255)) * PRIME) & MASK
    return h


def expected_result(values: list[int]) -> int:
    if (not isinstance(values, (list, tuple)) or len(values) < 1
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)):
        return INVALID_RESULT
    count = values[0]
    if not 0 <= count <= MAX_OPERATIONS or len(values) != 1 + 3 * count:
        return INVALID_RESULT
    table: dict[int, int] = {}
    h = OFFSET
    for index in range(count):
        opcode, key, value = values[1 + 3 * index:4 + 3 * index]
        if not 0 <= key <= 1_000_000:
            return INVALID_RESULT
        if opcode == 0:
            if not -1_000_000 <= value <= 1_000_000:
                return INVALID_RESULT
            if key not in table and len(table) >= MAX_ENTRIES:
                return INVALID_RESULT
            table[key] = value
        elif opcode == 1:
            if value != 0:
                return INVALID_RESULT
            h = _hash_value(h, table.get(key, I64_MIN))
        elif opcode == 2:
            if value != 0:
                return INVALID_RESULT
            table.pop(key, None)
        elif opcode == 3:
            if value != 0:
                return INVALID_RESULT
            h = _hash_value(h, int(key in table))
        elif opcode == 4:
            if key != 0 or value != 0:
                return INVALID_RESULT
            h = _hash_value(h, len(table))
        else:
            return INVALID_RESULT
    h = _hash_value(h, len(table))
    for key in sorted(table):
        h = _hash_value(_hash_value(h, key), table[key])
    return h if h < (1 << 63) else h - (1 << 64)
