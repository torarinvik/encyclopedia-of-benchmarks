"""Oracle for the bounded pinned shortest-remaining-time-first scheduler."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_JOBS = 32
MAX_ARRIVAL = 64
MAX_BURST = 128
SOURCE_SENTINEL = 999_999_999
MAX_PARSEABLE_INPUT_LENGTH = 1 + 2 * (MAX_JOBS + 1)
MAX_OUTPUT_BYTES = 8 * (1 + 2 * MAX_JOBS)
INVALID_RESULT = -1
INSUFFICIENT_OUTPUT_CAPACITY = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def calculate_waitingtime(arrival_times: Sequence[int], burst_times: Sequence[int]) -> list[int]:
    """Mirror the source's per-tick minimum scan and persistent tie state."""
    count = len(burst_times)
    remaining = list(burst_times)
    waiting = [0] * count
    completed = 0
    time = 0
    minimum = SOURCE_SENTINEL
    short = 0
    check = False

    while completed != count:
        for index in range(count):
            if (arrival_times[index] <= time and remaining[index] > 0
                    and remaining[index] < minimum):
                minimum = remaining[index]
                short = index
                check = True
        if not check:
            time += 1
            continue

        remaining[short] -= 1
        minimum = remaining[short]
        if minimum == 0:
            minimum = SOURCE_SENTINEL
        if remaining[short] == 0:
            completed += 1
            check = False
            finish_time = time + 1
            waiting[short] = max(finish_time - arrival_times[short] - burst_times[short], 0)
        time += 1
    return waiting


def calculate_turnaroundtime(burst_times: Sequence[int], waiting_times: Sequence[int]) -> list[int]:
    """Preserve the pinned source's elementwise burst-plus-waiting result."""
    return [burst_times[index] + waiting_times[index] for index in range(len(burst_times))]


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return byte status and [count, waiting times, turnaround times]."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null:
        return INVALID_RESULT, b""
    if (values is None or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH):
        return INVALID_RESULT, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT, b""
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return INVALID_RESULT, b""

    raw_count = values[0]
    if not 0 <= raw_count <= MAX_JOBS or len(values) != 1 + 2 * raw_count:
        return INVALID_RESULT, b""
    count = raw_count
    arrivals = list(values[1:1 + count])
    bursts = list(values[1 + count:])
    if any(not 0 <= arrival <= MAX_ARRIVAL for arrival in arrivals):
        return INVALID_RESULT, b""
    if any(not 1 <= burst <= MAX_BURST or burst >= SOURCE_SENTINEL for burst in bursts):
        return INVALID_RESULT, b""

    waiting = calculate_waitingtime(arrivals, bursts)
    turnaround = calculate_turnaroundtime(bursts, waiting)
    packed = (count, *waiting, *turnaround)
    output = b"".join(struct.pack("<q", value) for value in packed)
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and capacity < len(output)):
        return INSUFFICIENT_OUTPUT_CAPACITY, b""
    return len(output), output
