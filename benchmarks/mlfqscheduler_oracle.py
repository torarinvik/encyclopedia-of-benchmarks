"""Oracle for the bounded Java multi-level feedback queue scheduler trace."""
from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_LEVELS = 4
MAX_PROCESSES = 16
MAX_QUANTUM = 32
MAX_BURST = 1000
MAX_ARRIVAL = 1_000_000
MIN_I32 = -(1 << 31)
MAX_I32 = (1 << 31) - 1
MAX_VALID_INPUT_LENGTH = 2 + MAX_LEVELS + 3 * MAX_PROCESSES
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = 2 + 2 * MAX_PROCESSES
MAX_OUTPUT_BYTES = 8 * MAX_OUTPUT_ELEMENTS
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return final clock and ordered completion events as little-endian i64s."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return INVALID_RESULT, b""
    if (
        len(values) < 2
        or len(values) > MAX_INPUT_LENGTH
        or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)
    ):
        return INVALID_RESULT, b""

    level_count, process_count = values[0], values[1]
    if not 1 <= level_count <= MAX_LEVELS or not 0 <= process_count <= MAX_PROCESSES:
        return INVALID_RESULT, b""
    if len(values) != 2 + level_count + 3 * process_count:
        return INVALID_RESULT, b""
    quanta = values[2 : 2 + level_count]
    if any(not 1 <= quantum <= MAX_QUANTUM for quantum in quanta):
        return INVALID_RESULT, b""
    process_offset = 2 + level_count
    processes: list[list[int]] = []  # pid, remaining burst; arrival is intentionally ignored
    for index in range(process_count):
        pid, burst, arrival = values[process_offset + 3 * index : process_offset + 3 * index + 3]
        if not MIN_I32 <= pid <= MAX_I32 or not 0 <= burst <= MAX_BURST or not 0 <= arrival <= MAX_ARRIVAL:
            return INVALID_RESULT, b""
        processes.append([pid, burst])
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""

    queues: list[list[int]] = [list() for _ in range(level_count)]
    queues[0].extend(range(process_count))
    current_time = 0
    completions: list[tuple[int, int]] = []
    while any(queues):
        for level, queue in enumerate(queues):
            if not queue:
                continue
            process_index = queue.pop(0)
            pid, remaining = processes[process_index]
            time_slice = min(quanta[level], remaining)
            current_time += time_slice
            remaining -= time_slice
            processes[process_index][1] = remaining
            if remaining == 0:
                completions.append((pid, current_time))
            elif level + 1 < level_count:
                queues[level + 1].append(process_index)
            else:
                queue.append(process_index)

    results = [current_time, len(completions)]
    for pid, finish_time in completions:
        results.extend((pid, finish_time))
    output = b"".join(struct.pack("<q", result) for result in results)
    if output_is_null or (capacity is not None and capacity < len(output)):
        return OUTPUT_ERROR, b""
    return len(results), output
