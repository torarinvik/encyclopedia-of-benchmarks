"""Independent oracle for the pinned Java persistent immutable hash map."""

from __future__ import annotations

MAX_OPERATIONS = 256
INT32_MIN = -(1 << 31)
INT32_MAX = (1 << 31) - 1
FNV_OFFSET = 14695981039346656037
FNV_PRIME = 1099511628211
MASK64 = (1 << 64) - 1
MASK63 = (1 << 63) - 1


def _fnv_i64_record(values: list[int]) -> int:
    digest = FNV_OFFSET
    for value in values:
        bits = value & MASK64
        for shift in range(0, 64, 8):
            digest = ((digest ^ ((bits >> shift) & 0xFF)) * FNV_PRIME) & MASK64
    return digest & MASK63


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Apply the operation trace and return its framed hash, or -1 if invalid."""
    if (
        not isinstance(values, (list, tuple))
        or not 1 <= len(values) <= 1 + 3 * MAX_OPERATIONS
        or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)
    ):
        return -1
    count = values[0]
    if not 0 <= count <= MAX_OPERATIONS or len(values) != 1 + 3 * count:
        return -1

    entries: list[tuple[int, int]] = []
    trace: list[int] = []
    for index in range(count):
        operation, key, value = values[1 + 3 * index : 4 + 3 * index]
        if operation not in (0, 1, 2, 3) or not INT32_MIN <= key <= INT32_MAX or not INT32_MIN <= value <= INT32_MAX:
            return -1
        if operation == 0:
            if value == 0:
                return -1
            entries.append((key, value))
            trace.append(len(entries))
        elif operation == 1:
            found = next((entry_value for entry_key, entry_value in reversed(entries) if entry_key == key), 0)
            trace.append(found)
        elif operation == 2:
            trace.append(int(any(entry_key == key for entry_key, _ in reversed(entries))))
        else:
            trace.append(len(entries))
    return _fnv_i64_record([count, *trace])
