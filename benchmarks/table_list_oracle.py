"""Oracle for the bounded operation-trace port of TheAlgorithms/Lua table_list."""

from __future__ import annotations

import struct
from collections.abc import Sequence


MAX_OPERATION_COUNT = 32
MAX_LIST_LENGTH = 32
MIN_VALUE = -1_000_000
MAX_VALUE = 1_000_000
MIN_BOUNDS_INDEX = -1
MAX_BOUNDS_INDEX = MAX_LIST_LENGTH + 1
MAX_VALID_INPUT_LENGTH = 1 + 3 * MAX_OPERATION_COUNT
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_FIELDS = 594
MAX_OUTPUT_BYTES = MAX_OUTPUT_FIELDS * 8
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _invalid(values: object) -> bool:
    return (
        not isinstance(values, (list, tuple))
        or not 1 <= len(values) <= MAX_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
               for value in values)
    )


def expected_output(
    values: Sequence[int],
    capacity: int | None = None,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    """Validate and execute a fixed-width operation trace, returning its bytes."""
    if _invalid(values):
        return INVALID_RESULT, b""
    assert isinstance(values, (list, tuple))

    operation_count = values[0]
    if (not 0 <= operation_count <= MAX_OPERATION_COUNT
            or len(values) != 1 + 3 * operation_count):
        return INVALID_RESULT, b""

    items: list[int] = []
    records: list[int] = []
    cursor = 1
    for _ in range(operation_count):
        opcode, arg1, arg2 = values[cursor:cursor + 3]
        cursor += 3

        if opcode in (0, 1):  # push_head / push_tail
            if (not MIN_VALUE <= arg1 <= MAX_VALUE or arg2 != 0
                    or len(items) >= MAX_LIST_LENGTH):
                return INVALID_RESULT, b""
            if opcode == 0:
                items.insert(0, arg1)
            else:
                items.append(arg1)
            records.extend((opcode, 0))
        elif opcode == 2:  # pop_head
            if arg1 != 0 or arg2 != 0:
                return INVALID_RESULT, b""
            if items:
                records.extend((opcode, 1, items.pop(0)))
            else:
                records.extend((opcode, 0))
        elif opcode == 3:  # pop_tail
            if arg1 != 0 or arg2 != 0:
                return INVALID_RESULT, b""
            if items:
                records.extend((opcode, 1, items.pop()))
            else:
                records.extend((opcode, 0))
        elif opcode in (4, 5):  # get_head / get_tail
            if arg1 != 0 or arg2 != 0:
                return INVALID_RESULT, b""
            if items:
                value = items[0] if opcode == 4 else items[-1]
                records.extend((opcode, 1, value))
            else:
                records.extend((opcode, 0))
        elif opcode == 6:  # get(index), with source 1-based indexing
            if arg2 != 0 or not 1 <= arg1 <= len(items):
                return INVALID_RESULT, b""
            records.extend((opcode, 1, items[arg1 - 1]))
        elif opcode == 7:  # set(index, value)
            if (not 1 <= arg1 <= len(items)
                    or not MIN_VALUE <= arg2 <= MAX_VALUE):
                return INVALID_RESULT, b""
            items[arg1 - 1] = arg2
            records.extend((opcode, 0))
        elif opcode == 8:  # in_bounds(index)
            if (not MIN_BOUNDS_INDEX <= arg1 <= MAX_BOUNDS_INDEX
                    or arg2 != 0):
                return INVALID_RESULT, b""
            records.extend((opcode, 1, int(1 <= arg1 <= len(items))))
        elif opcode == 9:  # len()
            if arg1 != 0 or arg2 != 0:
                return INVALID_RESULT, b""
            records.extend((opcode, 1, len(items)))
        elif opcode in (10, 11):  # consume ipairs() / rpairs()
            if arg1 != 0 or arg2 != 0:
                return INVALID_RESULT, b""
            ordered = list(enumerate(items, start=1))
            if opcode == 11:
                ordered.reverse()
            records.extend((opcode, len(ordered)))
            for index, value in ordered:
                records.extend((index, value))
        else:
            return INVALID_RESULT, b""

    records.extend((12, len(items), *items))
    output = b"".join(struct.pack("<q", value) for value in records)

    if (type(output_is_null) is not bool
            or (capacity is not None
                and (type(capacity) is not int or capacity < 0))):
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and len(output) > capacity):
        return OUTPUT_ERROR, b""
    return len(output), output
