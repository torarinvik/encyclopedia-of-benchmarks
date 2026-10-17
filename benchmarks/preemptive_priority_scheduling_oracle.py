"""Oracle for the bounded pinned Java preemptive-priority scheduler."""

from __future__ import annotations

from collections.abc import Sequence
import heapq
import struct

MAX_PROCESS_COUNT = 8
MAX_PROCESS_ID = MAX_PROCESS_COUNT - 1
MAX_ARRIVAL_TIME = 16
MAX_BURST_TIME = 8
MAX_INPUT_LENGTH = 1 + 4 * MAX_PROCESS_COUNT
MAX_SCHEDULE_TICKS = MAX_ARRIVAL_TIME + MAX_PROCESS_COUNT * MAX_BURST_TIME
MAX_OUTPUT_BYTES = 4 * (1 + MAX_SCHEDULE_TICKS)
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
IDLE_PROCESS_ID = -1
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return ``[tick_count, id_or_idle_marker...]`` as little-endian i32s."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length < 0
    ):
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    if not 1 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT, b""
    if any(type(value) is not int or not I32_MIN <= value <= I32_MAX for value in values):
        return INVALID_RESULT, b""

    process_count = values[0]
    if not 0 <= process_count <= MAX_PROCESS_COUNT:
        return INVALID_RESULT, b""
    if len(values) != 1 + 4 * process_count:
        return INVALID_RESULT, b""

    processes: list[tuple[int, int, int, int, int]] = []
    seen_ids: set[int] = set()
    seen_priority_arrival: set[tuple[int, int]] = set()
    for index in range(process_count):
        offset = 1 + 4 * index
        process_id, arrival, burst, priority = values[offset : offset + 4]
        if not 0 <= process_id <= MAX_PROCESS_ID or process_id in seen_ids:
            return INVALID_RESULT, b""
        if not 0 <= arrival <= MAX_ARRIVAL_TIME or not 1 <= burst <= MAX_BURST_TIME:
            return INVALID_RESULT, b""
        priority_arrival = (priority, arrival)
        if priority_arrival in seen_priority_arrival:
            return INVALID_RESULT, b""
        seen_ids.add(process_id)
        seen_priority_arrival.add(priority_arrival)
        processes.append((process_id, arrival, burst, priority, index))

    pending = processes.copy()
    ready: list[tuple[int, int, int, int, int]] = []
    schedule: list[int] = []
    current_time = 0
    while pending or ready:
        arrived: list[tuple[int, int, int, int, int]] = []
        still_pending: list[tuple[int, int, int, int, int]] = []
        for process in pending:
            if process[1] <= current_time:
                arrived.append(process)
            else:
                still_pending.append(process)
        pending = still_pending
        for process_id, arrival, burst, priority, index in arrived:
            heapq.heappush(ready, (-priority, arrival, index, process_id, burst))

        if ready:
            neg_priority, arrival, index, process_id, remaining = heapq.heappop(ready)
            schedule.append(process_id)
            remaining -= 1
            if remaining > 0:
                heapq.heappush(ready, (neg_priority, arrival, index, process_id, remaining))
        else:
            schedule.append(IDLE_PROCESS_ID)
        current_time += 1

    words = [len(schedule), *schedule]
    encoded = struct.pack("<" + "i" * len(words), *words)
    if len(encoded) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null or (
        output_capacity is not None and output_capacity < len(encoded)
    ):
        return OUTPUT_ERROR, b""
    return len(encoded), encoded
