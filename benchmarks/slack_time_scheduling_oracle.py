"""Oracle for the bounded Java slack-time stable-sort contract."""
from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_TASKS = 64
MAX_TIME = 1_000_000
INVALID_RESULT = -1
INSUFFICIENT_OUTPUT_CAPACITY = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null:
        return INVALID_RESULT, b""
    if values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return INVALID_RESULT, b""
    if not 1 <= len(values) <= 1 + 2 * MAX_TASKS:
        return INVALID_RESULT, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT, b""
    n = values[0]
    if not 0 <= n <= MAX_TASKS or len(values) != 1 + 2 * n:
        return INVALID_RESULT, b""
    tasks = [(values[1 + 2 * i], values[2 + 2 * i]) for i in range(n)]
    if any(execution < 0 or execution > MAX_TIME or deadline < 0 or deadline > MAX_TIME
           for execution, deadline in tasks):
        return INVALID_RESULT, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    if output_is_null:
        return INSUFFICIENT_OUTPUT_CAPACITY, b""
    order = sorted(range(n), key=lambda i: tasks[i][1] - tasks[i][0])
    output = b"".join(struct.pack("<q", index) for index in order)
    if capacity is not None and capacity < len(output):
        return INSUFFICIENT_OUTPUT_CAPACITY, b""
    return len(output), output
