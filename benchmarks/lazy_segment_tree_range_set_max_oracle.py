"""Independent array oracle for the bounded range-set/range-maximum workload."""

from __future__ import annotations

MAX_N = 256
MAX_OPERATIONS = 512
MAX_VALUE = 1_000_000
CHECKSUM_OFFSET = MAX_VALUE + 1
MAX_INPUT_LENGTH = 2 + MAX_N + 4 * MAX_OPERATIONS


def oracle(packed: list[int]) -> int:
    if not isinstance(packed, list) or any(type(value) is not int for value in packed):
        return -1
    if len(packed) < 3 or len(packed) > MAX_INPUT_LENGTH:
        return -1
    n, operation_count = packed[0], packed[1]
    if not 1 <= n <= MAX_N or not 0 <= operation_count <= MAX_OPERATIONS:
        return -1
    if len(packed) < 2 + n:
        return -1
    values = packed[2:2 + n]
    if any(not -MAX_VALUE <= value <= MAX_VALUE for value in values):
        return -1
    offset = 2 + n
    parsed: list[tuple[int, int, int, int | None]] = []
    for _ in range(operation_count):
        if offset >= len(packed):
            return -1
        opcode = packed[offset]
        width = 3 if opcode == 0 else 4 if opcode == 1 else 0
        if width == 0 or offset + width > len(packed):
            return -1
        left, right = packed[offset + 1], packed[offset + 2]
        if not 0 <= left < right <= n:
            return -1
        assigned = packed[offset + 3] if opcode == 1 else None
        if assigned is not None and not -MAX_VALUE <= assigned <= MAX_VALUE:
            return -1
        parsed.append((opcode, left, right, assigned))
        offset += width
    if offset != len(packed):
        return -1

    checksum = 0
    query_ordinal = 0
    for opcode, left, right, assigned in parsed:
        if opcode == 1:
            assert assigned is not None
            values[left:right] = [assigned] * (right - left)
        else:
            query_ordinal += 1
            checksum += query_ordinal * (max(values[left:right]) + CHECKSUM_OFFSET)
    return checksum
