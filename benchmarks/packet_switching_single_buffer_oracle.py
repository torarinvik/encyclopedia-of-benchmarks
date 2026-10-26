"""Primary bounded simulator for the chapter's single-buffer greedy policies."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_PACKETS = 16
MAX_SLOTS = 8
MAX_INPUT_LENGTH = 38
MAX_OUTPUT_BYTES = 64
BETA = 15


def _decode(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 5 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    mode, buffer_size, beta, slots, packet_count = values[:5]
    if mode not in (0, 1, 2) or not 1 <= buffer_size <= 4 or not 1 <= slots <= MAX_SLOTS:
        return None
    if not 0 <= packet_count <= MAX_PACKETS or len(values) != 5 + 2 * packet_count:
        return None
    if (mode == 0 and beta != 0) or (mode != 0 and beta != BETA):
        return None
    packets = []
    previous_slot = -1
    for packet_id in range(packet_count):
        arrival_slot, value = values[5 + 2 * packet_id:7 + 2 * packet_id]
        if not 0 <= arrival_slot < slots or arrival_slot < previous_slot or not 1 <= value <= 100:
            return None
        packets.append((arrival_slot, value))
        previous_slot = arrival_slot
    return mode, buffer_size, slots, packets


def _payload(decoded) -> bytes:
    mode, capacity, slots, packets = decoded
    fifo: list[tuple[int, int]] = []
    output = [-1] * slots
    next_packet = 0
    for slot in range(slots):
        while next_packet < len(packets) and packets[next_packet][0] == slot:
            value = packets[next_packet][1]
            packet = (next_packet, value)
            preempt_at = None
            if mode == 1:
                for index, (_, old_value) in enumerate(fifo):
                    if old_value * BETA <= value:
                        preempt_at = index
                        break
            elif mode == 2:
                for index, (_, old_value) in enumerate(fifo):
                    next_value_ok = index + 1 == len(fifo) or old_value <= fifo[index + 1][1]
                    if old_value * BETA < value and next_value_ok:
                        preempt_at = index
                        break
            if preempt_at is not None:
                fifo.pop(preempt_at)
                fifo.append(packet)
            elif len(fifo) < capacity:
                fifo.append(packet)
            else:
                smallest = min(old_value for _, old_value in fifo)
                if value > smallest:
                    evict = next(index for index, (_, old_value) in enumerate(fifo)
                                 if old_value == smallest)
                    fifo.pop(evict)
                    fifo.append(packet)
            next_packet += 1
        if fifo:
            output[slot] = fifo.pop(0)[0]
    return struct.pack("<" + "q" * slots, *output)


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
