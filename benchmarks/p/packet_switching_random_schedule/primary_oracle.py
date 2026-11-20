"""Primary bounded reference for the Random Schedule queue policy."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT_LENGTH = 67
MAX_PARSEABLE_INPUT_LENGTH = 68
MAX_OUTPUT_BYTES = 64
WORKSPACE_BYTES = 512
MAX_PRIORITY = (1 << 32) - 1


def _decode(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    queues, capacity, slots = values[:3]
    if not 2 <= queues <= 4 or not 1 <= capacity <= 4 or not 1 <= slots <= 8:
        return None
    matrix_length = queues * slots
    expected = 3 + 2 * matrix_length
    if len(values) != expected:
        return None
    arrivals = values[3:3 + matrix_length]
    priorities = values[3 + matrix_length:]
    if any(value not in (0, 1) for value in arrivals):
        return None
    if any(value < 0 or value > MAX_PRIORITY for value in priorities):
        return None
    return queues, capacity, slots, arrivals, priorities


def _payload(decoded) -> bytes:
    queues, capacity, slots, arrivals, priorities = decoded
    loads = [0] * queues
    tags: list[list[list[int | bool]]] = [[] for _ in range(queues)]
    schedule: list[int] = []
    for slot in range(slots):
        row = slot * queues
        for queue in range(queues):
            index = row + queue
            if arrivals[index] and loads[queue] < capacity:
                if len(tags[queue]) == capacity:
                    del tags[queue][0]
                tags[queue].append([priorities[index], False])
                loads[queue] += 1
        selected_queue = -1
        selected_tag = -1
        selected_priority = -1
        for queue in range(queues):
            for tag_index, (priority, marked) in enumerate(tags[queue]):
                if marked:
                    continue
                if (selected_queue < 0 or priority > selected_priority
                        or priority == selected_priority and
                        (queue < selected_queue or queue == selected_queue
                         and tag_index < selected_tag)):
                    selected_queue = queue
                    selected_tag = tag_index
                    selected_priority = priority
        if selected_queue >= 0:
            tags[selected_queue][selected_tag][1] = True
        else:
            selected_queue = next((queue for queue, load in enumerate(loads) if load), -1)
        if selected_queue < 0:
            schedule.append(-1)
        else:
            schedule.append(selected_queue)
            loads[selected_queue] -= 1
    return struct.pack("<" + "q" * slots, *schedule)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    if (not isinstance(values, (list, tuple))
            or input_length is not None and input_length != len(values)):
        return -1, b""
    decoded = _decode(values)
    if decoded is None:
        return -1, b""
    payload = _payload(decoded)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
