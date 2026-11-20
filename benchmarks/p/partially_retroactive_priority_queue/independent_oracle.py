"""Independent replay oracle for retroactive priority-queue fixtures."""

from __future__ import annotations

import heapq
import struct

from .primary_oracle import (
    INVALID_RESULT,
    MAX_N,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_Q,
    OUTPUT_ERROR,
)


def expected_result(
    values: list[int],
    input_is_null: bool = False,
    input_length: int | None = None,
    output_is_null: bool = False,
    output_capacity: int | None = None,
) -> tuple[int, bytes]:
    if input_is_null or not isinstance(values, list):
        return INVALID_RESULT, b""
    length = len(values) if input_length is None else input_length
    if length != len(values) or length < 2 or length > MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT, b""
    n, q = values[0], values[1]
    if not (1 <= n <= MAX_N and 1 <= q <= MAX_Q) or length != 2 + 2 * n + 3 * q:
        return INVALID_RESULT, b""
    timeline: list[tuple[int, int]] = []
    at = 2
    for _ in range(n):
        kind, value = values[at], values[at + 1]
        at += 2
        if kind == 0:
            if not 0 <= value <= 1_000_000:
                return INVALID_RESULT, b""
        elif kind in (1, 2):
            if value != -1:
                return INVALID_RESULT, b""
        else:
            return INVALID_RESULT, b""
        timeline.append((kind, value))
    updates: list[tuple[int, int, int]] = []
    for _ in range(q):
        index, kind, value = values[at], values[at + 1], values[at + 2]
        at += 3
        if not 0 <= index < n or kind not in (0, 1, 2):
            return INVALID_RESULT, b""
        if kind == 0:
            if not 0 <= value <= 1_000_000:
                return INVALID_RESULT, b""
        elif value != -1:
            return INVALID_RESULT, b""
        updates.append((index, kind, value))
    result = bytearray()
    for index, kind, value in updates:
        timeline[index] = (kind, value)
        heap: list[int] = []
        for op, item in timeline:
            if op == 0:
                heapq.heappush(heap, item)
            elif op == 1 and heap:
                heapq.heappop(heap)
        result.extend(struct.pack("<qq", len(heap), sum(heap)))
    if output_is_null or (output_capacity is not None and output_capacity < len(result)):
        return OUTPUT_ERROR, b""
    return len(result), bytes(result)
