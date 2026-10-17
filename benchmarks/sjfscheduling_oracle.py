"""Oracle for bounded nonpreemptive shortest-job-first scheduling."""

from __future__ import annotations

from collections.abc import Sequence
import struct


MAX_PROCESS_COUNT = 64
MIN_ARRIVAL_TIME = 0
MAX_ARRIVAL_TIME = 255
MIN_BURST_TIME = 1
MAX_BURST_TIME = 255
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_PROCESS_COUNT
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 4 * MAX_PROCESS_COUNT
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the pinned scheduler's process-index order as LE signed i32s."""
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
    if not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT, b""
    if any(type(value) is not int or not I32_MIN <= value <= I32_MAX
           for value in values):
        return INVALID_RESULT, b""

    process_count = values[0]
    if not 0 <= process_count <= MAX_PROCESS_COUNT:
        return INVALID_RESULT, b""
    if len(values) != 1 + 2 * process_count:
        return INVALID_RESULT, b""

    processes: list[tuple[int, int, int]] = []
    for process_index in range(process_count):
        arrival = values[1 + 2 * process_index]
        burst = values[2 + 2 * process_index]
        if not MIN_ARRIVAL_TIME <= arrival <= MAX_ARRIVAL_TIME:
            return INVALID_RESULT, b""
        if not MIN_BURST_TIME <= burst <= MAX_BURST_TIME:
            return INVALID_RESULT, b""
        processes.append((process_index, arrival, burst))

    # Python's sort and min are stable, matching the source's stable arrival
    # sort and first minimum from its ordered ready-list stream.
    processes.sort(key=lambda process: process[1])
    ready: list[tuple[int, int, int]] = []
    next_process = 0
    current_time = 0
    schedule: list[int] = []

    while len(schedule) < process_count:
        while (next_process < process_count
               and processes[next_process][1] <= current_time):
            ready.append(processes[next_process])
            next_process += 1

        if not ready:
            current_time += 1
            continue

        selected = min(ready, key=lambda process: process[2])
        ready.remove(selected)
        schedule.append(selected[0])
        current_time += selected[2]

    encoded = struct.pack("<" + "i" * len(schedule), *schedule) if schedule else b""
    if len(encoded) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null or (
        output_capacity is not None and output_capacity < len(encoded)
    ):
        return OUTPUT_ERROR, b""
    return len(encoded), encoded
