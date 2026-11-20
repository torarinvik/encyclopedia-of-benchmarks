"""Independent abstract priority-queue oracle for Calendar Queue traces."""

from __future__ import annotations

import heapq
import struct
from collections.abc import Sequence

INPUT_LIMIT = 258
OP_LIMIT = 128
ACTIVE_LIMIT = 64
TIME_LIMIT = 1_000_000


def _valid_frame(raw: Sequence[int]):
    if len(raw) < 1 or len(raw) > INPUT_LIMIT:
        return None
    if any(type(word) is not int or word < -(1 << 63) or word >= (1 << 63)
           for word in raw):
        return None
    steps = raw[0]
    if steps < 0 or steps > OP_LIMIT or len(raw) != 1 + 2 * steps:
        return None
    return [(raw[1 + 2 * index], raw[2 + 2 * index]) for index in range(steps)]


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if input_length is not None and (
            type(input_length) is not int or input_length < 0 or input_length > INPUT_LIMIT):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    operations = _valid_frame(values)
    if operations is None:
        return -1, b""

    heap: list[tuple[int, int]] = []
    next_id = 0
    last_priority = 0
    trace: list[int] = []
    for opcode, argument in operations:
        if opcode == 1:
            if argument < 0 or argument > TIME_LIMIT or argument < last_priority:
                return -1, b""
            if len(heap) >= ACTIVE_LIMIT:
                return -1, b""
            heapq.heappush(heap, (argument, next_id))
            next_id += 1
        elif opcode == 2:
            if argument != 0 or not heap:
                return -1, b""
            priority, event_id = heapq.heappop(heap)
            last_priority = priority
            trace.extend((event_id, priority))
        else:
            return -1, b""

    payload = b"".join(struct.pack("<q", word)
                       for word in (len(trace) // 2, *trace))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
