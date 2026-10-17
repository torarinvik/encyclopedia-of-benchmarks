"""Oracle for the bounded pinned Python multilevel feedback queue."""

from __future__ import annotations

from collections import deque
from collections.abc import Sequence
import struct

MAX_QUEUE_COUNT = 4
MAX_PROCESS_COUNT = 8
MAX_TIME_SLICE = 16
MAX_BURST_TIME = 16
MAX_INPUT_LENGTH = 2 + (MAX_QUEUE_COUNT - 1) + MAX_PROCESS_COUNT
MAX_TOTAL_BURST = MAX_PROCESS_COUNT * MAX_BURST_TIME
MAX_OUTPUT_BYTES = 4 * (1 + 4 * MAX_PROCESS_COUNT)
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
    """Return finish-order ``(id, waiting, turnaround, stop_time)`` records."""
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
    if not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT, b""
    if any(type(value) is not int or not I32_MIN <= value <= I32_MAX for value in values):
        return INVALID_RESULT, b""

    queue_count, process_count = values[:2]
    if not 1 <= queue_count <= MAX_QUEUE_COUNT:
        return INVALID_RESULT, b""
    if not 0 <= process_count <= MAX_PROCESS_COUNT:
        return INVALID_RESULT, b""
    slice_count = queue_count - 1
    if len(values) != 2 + slice_count + process_count:
        return INVALID_RESULT, b""
    time_slices = list(values[2 : 2 + slice_count])
    bursts = list(values[2 + slice_count :])
    if any(not 1 <= time_slice <= MAX_TIME_SLICE for time_slice in time_slices):
        return INVALID_RESULT, b""
    if any(not 1 <= burst <= MAX_BURST_TIME for burst in bursts):
        return INVALID_RESULT, b""

    # The bounded input fixes every arrival time to zero, so the source's
    # nonzero-arrival current_time += arrival_time quirk is not observable.
    ready = deque(
        {
            "id": process_id,
            "remaining": burst,
            "waiting": 0,
            "turnaround": 0,
            "stop": 0,
        }
        for process_id, burst in enumerate(bursts)
    )
    finished: list[dict[str, int]] = []
    current_time = 0

    for time_slice in time_slices:
        finished_this_level: list[dict[str, int]] = []
        for _ in range(len(ready)):
            process = ready.popleft()
            process["waiting"] += current_time - process["stop"]
            if process["remaining"] > time_slice:
                current_time += time_slice
                process["remaining"] -= time_slice
                process["stop"] = current_time
                ready.append(process)
            else:
                current_time += process["remaining"]
                process["remaining"] = 0
                process["stop"] = current_time
                process["turnaround"] = current_time
                finished_this_level.append(process)
        finished.extend(finished_this_level)

    finished_this_level = []
    while ready:
        process = ready.popleft()
        process["waiting"] += current_time - process["stop"]
        current_time += process["remaining"]
        process["remaining"] = 0
        process["stop"] = current_time
        process["turnaround"] = current_time
        finished_this_level.append(process)
    finished.extend(finished_this_level)

    words = [len(finished)]
    for process in finished:
        words.extend(
            (
                process["id"],
                process["waiting"],
                process["turnaround"],
                process["stop"],
            )
        )
    encoded = struct.pack("<" + "i" * len(words), *words)
    if len(encoded) > MAX_OUTPUT_BYTES or current_time > MAX_TOTAL_BURST:
        return INVALID_RESULT, b""
    if output_is_null or (
        output_capacity is not None and output_capacity < len(encoded)
    ):
        return OUTPUT_ERROR, b""
    return len(encoded), encoded
