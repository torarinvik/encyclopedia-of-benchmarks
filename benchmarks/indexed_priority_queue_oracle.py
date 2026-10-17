"""Independent state oracle for the bounded Java indexed min-priority queue."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_EVENTS = 256
MAX_INPUT_VALUES = 1538
MAX_OUTPUT_BYTES = 12_288
MAX_ACTIVE = 64
MIN_I32 = -(1 << 31)
MAX_I32 = (1 << 31) - 1


def expected_output(values: Sequence[int]) -> tuple[int, bytes]:
    """Validate and simulate a bounded event trace, returning six-i64 records."""
    if not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_VALUES:
        return -1, b""
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return -1, b""

    event_count = values[0]
    if not 0 <= event_count <= MAX_EVENTS or len(values) != 1 + 6 * event_count:
        return -1, b""
    if event_count == 0:
        return 0, b""

    entries: dict[int, int] = {}
    records: list[tuple[int, int, int, int, int, int]] = []
    for event_index in range(event_count):
        start = 1 + event_index * 6
        opcode, element_id, key, reserved0, reserved1, reserved2 = values[start : start + 6]
        if (reserved0, reserved1, reserved2) != (0, 0, 0):
            return -1, b""

        status = 1
        result_id = 0
        result_key = 0
        if opcode == 0:  # offer
            if not 0 <= element_id < MAX_ACTIVE or not MIN_I32 <= key <= MAX_I32:
                return -1, b""
            if element_id in entries or len(entries) >= MAX_ACTIVE or key in entries.values():
                return -1, b""
            entries[element_id] = key
        elif opcode in (1, 2):  # peek / poll
            if element_id != 0 or key != 0:
                return -1, b""
            if entries:
                minimum_id = min(entries, key=entries.__getitem__)
                status = 1
                result_id, result_key = minimum_id, entries[minimum_id]
                if opcode == 2:
                    del entries[minimum_id]
            else:
                status = 0
        elif opcode in (3, 4):  # remove / contains
            if not 0 <= element_id < MAX_ACTIVE or key != 0:
                return -1, b""
            status = int(element_id in entries)
            if opcode == 3 and status:
                del entries[element_id]
        elif opcode in (5, 6, 7):  # change / decrease / increase key
            if not 0 <= element_id < MAX_ACTIVE or not MIN_I32 <= key <= MAX_I32:
                return -1, b""
            if element_id not in entries:
                return -1, b""
            old_key = entries[element_id]
            if opcode == 6 and key >= old_key:
                return -1, b""
            if opcode == 7 and key <= old_key:
                return -1, b""
            if any(other_id != element_id and other_key == key for other_id, other_key in entries.items()):
                return -1, b""
            entries[element_id] = key
        elif opcode in (8, 9, 10):  # clear / size / is_empty
            if element_id != 0 or key != 0:
                return -1, b""
            if opcode == 8:
                entries.clear()
            elif opcode == 9:
                result_id = len(entries)
            else:
                result_id = int(not entries)
        else:
            return -1, b""

        if entries:
            minimum_id = min(entries, key=entries.__getitem__)
            minimum_key = entries[minimum_id]
        else:
            minimum_id = minimum_key = 0
        records.append((status, result_id, result_key, len(entries), minimum_id, minimum_key))

    payload = b"".join(struct.pack("<6q", *record) for record in records)
    return len(payload), payload
