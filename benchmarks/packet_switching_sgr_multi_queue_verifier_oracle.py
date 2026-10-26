"""Independent verifier for the bounded multi-queue SGR trace."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT_LENGTH = 36
MAX_OUTPUT_BYTES = 64


def _read(values: Sequence[int] | None):
    if not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(type(item) is not int or not -(1 << 63) <= item < (1 << 63) for item in values):
        return None
    queue_count, capacity, time_count = values[0:3]
    if not 2 <= queue_count <= 4 or not 1 <= capacity <= 4 or not 1 <= time_count <= 8:
        return None
    if len(values) != 3 + queue_count * time_count:
        return None
    matrix = tuple(tuple(values[3 + t * queue_count + q]
                         for q in range(queue_count)) for t in range(time_count))
    if any(arrivals < 0 or arrivals > capacity for row in matrix for arrivals in row):
        return None
    return queue_count, capacity, matrix


def _independent_trace(parsed):
    queue_count, capacity, arrivals = parsed
    loads = [0] * queue_count
    observed = [0] * queue_count
    trace: list[int] = []
    half = capacity // 2
    for row in arrivals:
        loads = [min(capacity, loads[q] + row[q]) for q in range(queue_count)]
        observed = [max(observed[q], loads[q]) for q in range(queue_count)]
        active = [q for q, load in enumerate(loads) if load]
        if not active:
            trace.append(-1)
            observed = [0] * queue_count
            continue
        crowded = [q for q in active if loads[q] > half]
        if crowded:
            candidates = active
        else:
            fresh = [q for q in active if observed[q] != capacity]
            candidates = fresh or active
        # Sort by descending current occupancy, then ascending queue number.
        chosen = sorted(candidates, key=lambda q: (loads[q] * -1, q))[0]
        trace.append(chosen)
        loads[chosen] -= 1
        if max(loads) == 0:
            observed = [0] * queue_count
    return tuple(trace)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _read(values)
    if parsed is None:
        return -1, b""
    trace = _independent_trace(parsed)
    payload = struct.pack("<" + "q" * len(trace), *trace)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
