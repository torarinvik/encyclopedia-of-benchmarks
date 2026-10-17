"""Oracle for the bounded TheAlgorithms two-queue stack trace."""
from __future__ import annotations
from collections import deque
from collections.abc import Sequence
import struct

MAX_OPERATIONS = 128
MAX_INPUT_LENGTH = 1 + 2 * MAX_OPERATIONS
MAX_OUTPUT_BYTES = 16 * MAX_OPERATIONS
INVALID_RESULT = -1
INSUFFICIENT_OUTPUT_CAPACITY = -2
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1

def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return INVALID_RESULT, b""
    if not values or len(values) > MAX_INPUT_LENGTH:
        return INVALID_RESULT, b""
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return INVALID_RESULT, b""
    count = values[0]
    if not 0 <= count <= MAX_OPERATIONS or len(values) != 1 + 2 * count:
        return INVALID_RESULT, b""

    main: deque[int] = deque()
    temp: deque[int] = deque()
    records: list[tuple[int, int]] = []
    pos = 1
    for _ in range(count):
        op, value = values[pos], values[pos + 1]
        pos += 2
        if op == 0:
            if not I32_MIN <= value <= I32_MAX:
                return INVALID_RESULT, b""
            temp.append(value)
            while main:
                temp.append(main.popleft())
            main, temp = temp, main
        elif op == 1:
            if value != 0 or not main:
                return INVALID_RESULT, b""
            records.append((0, main.popleft()))
        elif op == 2:
            if value != 0:
                return INVALID_RESULT, b""
            records.append((0, main[0]) if main else (1, 0))
        else:
            return INVALID_RESULT, b""

    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    output = b"".join(struct.pack("<qq", tag, value) for tag, value in records)
    if output_is_null or (capacity is not None and capacity < len(output)):
        return INSUFFICIENT_OUTPUT_CAPACITY, b""
    return len(output), output
