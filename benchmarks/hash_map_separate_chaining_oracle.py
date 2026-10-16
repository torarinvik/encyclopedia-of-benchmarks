"""Oracle for bounded non-null integer maps using separate chaining semantics."""

from __future__ import annotations

MAX_OPERATIONS = 512
MAX_ENTRIES = 128
MAX_KEY = 99_999
MIN_VALUE = -(1 << 31)
MAX_VALUE = (1 << 31) - 1
MAX_INPUT_LENGTH = 1 + 3 * MAX_OPERATIONS
FNV_OFFSET = 0xCBF29CE484222325
FNV_PRIME = 0x100000001B3
MASK64 = (1 << 64) - 1
MASK63 = (1 << 63) - 1
INVALID_RESULT = -1


def _byte(h: int, value: int) -> int:
    return ((h ^ (value & 255)) * FNV_PRIME) & MASK64


def _i32(h: int, value: int) -> int:
    bits = value & 0xFFFFFFFF
    for shift in (0, 8, 16, 24):
        h = _byte(h, bits >> shift)
    return h


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    operation_count = values[0]
    if (not 0 <= operation_count <= MAX_OPERATIONS
            or len(values) != 1 + 3 * operation_count):
        return INVALID_RESULT

    table: dict[int, int] = {}
    h = FNV_OFFSET
    for operation in range(operation_count):
        opcode, key, value = values[1 + 3 * operation:4 + 3 * operation]
        result_code = 0

        if opcode == 0:
            if not 0 <= key <= MAX_KEY or not MIN_VALUE <= value <= MAX_VALUE:
                return INVALID_RESULT
            if key not in table and len(table) >= MAX_ENTRIES:
                return INVALID_RESULT
            table[key] = value
        elif opcode == 1:
            if not 0 <= key <= MAX_KEY or value != 0:
                return INVALID_RESULT
            if key in table:
                result_code = 1
                h = _byte(_byte(h, opcode), result_code)
                h = _i32(h, table[key])
                continue
        elif opcode == 2:
            if not 0 <= key <= MAX_KEY or value != 0:
                return INVALID_RESULT
            table.pop(key, None)
        elif opcode == 3:
            if not 0 <= key <= MAX_KEY or value != 0:
                return INVALID_RESULT
            result_code = int(key in table)
        elif opcode == 4:
            if key != 0 or value != 0:
                return INVALID_RESULT
            table.clear()
        else:
            return INVALID_RESULT

        h = _byte(_byte(h, opcode), result_code)

    return h & MASK63
