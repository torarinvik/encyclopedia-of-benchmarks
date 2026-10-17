"""Oracle for the bounded fixed-quantum round-robin scheduler."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_JOBS = 32
MAX_BURST = 4096
QUANTUM = 2
MAX_PARSEABLE_INPUT_LENGTH = MAX_JOBS + 2
MAX_OUTPUT_BYTES = 8 * (1 + 2 * MAX_JOBS)
INVALID_RESULT = -1
INSUFFICIENT_OUTPUT_CAPACITY = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def calculate_waiting_times(burst_times: Sequence[int]) -> list[int]:
    """Run the pinned source's input-order loop with its fixed quantum of two."""
    remaining = list(burst_times)
    waiting = [0] * len(remaining)
    elapsed = 0
    while True:
        done = True
        for index, burst in enumerate(burst_times):
            if remaining[index] > 0:
                done = False
                if remaining[index] > QUANTUM:
                    elapsed += QUANTUM
                    remaining[index] -= QUANTUM
                else:
                    elapsed += remaining[index]
                    waiting[index] = elapsed - burst
                    remaining[index] = 0
        if done:
            return waiting


def calculate_turn_around_times(
    burst_times: Sequence[int], waiting_times: Sequence[int]
) -> list[int]:
    """Preserve the source's elementwise burst+waiting calculation via zip."""
    return [burst + waiting for burst, waiting in zip(burst_times, waiting_times)]


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return output byte count and [count, waiting..., turnaround...] bytes."""
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
    if not 0 <= raw_count <= MAX_JOBS or len(values) != raw_count + 1:
        return INVALID_RESULT, b""
    bursts = list(values[1:])
    if any(not 0 <= burst <= MAX_BURST for burst in bursts):
        return INVALID_RESULT, b""

    waiting = calculate_waiting_times(bursts)
    turnaround = calculate_turn_around_times(bursts, waiting)
    packed = (raw_count, *waiting, *turnaround)
    output = b"".join(struct.pack("<q", value) for value in packed)
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and capacity < len(output)):
        return INSUFFICIENT_OUTPUT_CAPACITY, b""
    return len(output), output
