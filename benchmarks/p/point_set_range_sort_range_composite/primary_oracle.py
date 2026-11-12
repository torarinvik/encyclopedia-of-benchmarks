"""Primary bounded list-simulation oracle for point-set range-sort composition."""

from __future__ import annotations

from collections.abc import Sequence

MODULUS = 998_244_353
MAX_N = 16
MAX_OPERATIONS = 32
MAX_PRIORITY = 1_000_000_000
MAX_INPUT_LENGTH = 210
INVALID_RESULT = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(
    values: Sequence[int] | None,
    *,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    if type(input_is_null) is not bool:
        return INVALID_RESULT
    if input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH):
        return INVALID_RESULT
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT
    if (not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT
    n, operation_count = values[0], values[1]
    if not 1 <= n <= MAX_N or not 1 <= operation_count <= MAX_OPERATIONS:
        return INVALID_RESULT
    if len(values) < 2 + 3 * n:
        return INVALID_RESULT

    records: list[tuple[int, int, int]] = []
    seen_priorities: set[int] = set()
    cursor = 2
    for _ in range(n):
        priority, multiplier, offset = values[cursor:cursor + 3]
        cursor += 3
        if (not 0 <= priority <= MAX_PRIORITY or priority in seen_priorities
                or not 1 <= multiplier < MODULUS or not 0 <= offset < MODULUS):
            return INVALID_RESULT
        seen_priorities.add(priority)
        records.append((priority, multiplier, offset))

    checksum = 0
    query_number = 0
    for _ in range(operation_count):
        if cursor >= len(values):
            return INVALID_RESULT
        opcode = values[cursor]
        cursor += 1
        if opcode == 0:
            if len(values) - cursor < 4:
                return INVALID_RESULT
            index, priority, multiplier, offset = values[cursor:cursor + 4]
            cursor += 4
            if (not 0 <= index < n or not 0 <= priority <= MAX_PRIORITY
                    or priority in seen_priorities or not 1 <= multiplier < MODULUS
                    or not 0 <= offset < MODULUS):
                return INVALID_RESULT
            seen_priorities.add(priority)
            records[index] = (priority, multiplier, offset)
        elif opcode == 1:
            if len(values) - cursor < 3:
                return INVALID_RESULT
            left, right, argument = values[cursor:cursor + 3]
            cursor += 3
            if not 0 <= left < right <= n or not 0 <= argument < MODULUS:
                return INVALID_RESULT
            result = argument
            for _, multiplier, offset in records[left:right]:
                result = (multiplier * result + offset) % MODULUS
            query_number += 1
            checksum = (checksum + query_number * result) % MODULUS
        elif opcode in (2, 3):
            if len(values) - cursor < 2:
                return INVALID_RESULT
            left, right = values[cursor:cursor + 2]
            cursor += 2
            if not 0 <= left < right <= n:
                return INVALID_RESULT
            records[left:right] = sorted(records[left:right], key=lambda record: record[0], reverse=opcode == 3)
        else:
            return INVALID_RESULT
    return checksum if cursor == len(values) else INVALID_RESULT
