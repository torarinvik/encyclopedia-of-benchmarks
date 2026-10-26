"""Primary bounded oracle for multi-queue SGR unit-value packet switching."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_QUEUES = 4
MAX_BUFFER = 4
MAX_SLOTS = 8
MAX_INPUT_LENGTH = 36
MAX_OUTPUT_BYTES = 64


def _decode(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    queues, buffer_size, slots = values[:3]
    if not 2 <= queues <= MAX_QUEUES or not 1 <= buffer_size <= MAX_BUFFER:
        return None
    if not 1 <= slots <= MAX_SLOTS or len(values) != 3 + queues * slots:
        return None
    arrivals = [list(values[3 + slot * queues:3 + (slot + 1) * queues])
                for slot in range(slots)]
    if any(value < 0 or value > buffer_size for row in arrivals for value in row):
        return None
    return queues, buffer_size, slots, arrivals


def _payload(decoded) -> bytes:
    queues, buffer_size, slots, arrivals = decoded
    occupancy = [0] * queues
    peak = [0] * queues
    schedule: list[int] = []
    threshold = buffer_size // 2
    for row in arrivals:
        for queue in range(queues):
            occupancy[queue] = min(buffer_size, occupancy[queue] + row[queue])
            peak[queue] = max(peak[queue], occupancy[queue])
        nonempty = [queue for queue in range(queues) if occupancy[queue] > 0]
        if not nonempty:
            schedule.append(-1)
            peak = [0] * queues
            continue
        if any(occupancy[queue] > threshold for queue in nonempty):
            eligible = nonempty
        else:
            underfull_history = [queue for queue in nonempty if peak[queue] < buffer_size]
            eligible = underfull_history if underfull_history else nonempty
        selected = min(eligible, key=lambda queue: (-occupancy[queue], queue))
        occupancy[selected] -= 1
        schedule.append(selected)
        if not any(occupancy):
            peak = [0] * queues
    return struct.pack("<" + "q" * slots, *schedule)


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
    decoded = _decode(values)
    if decoded is None:
        return -1, b""
    payload = _payload(decoded)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
