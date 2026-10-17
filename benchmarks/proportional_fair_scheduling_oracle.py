"""Oracle for bounded Java-style proportional fair scheduling."""

from __future__ import annotations

import struct
from typing import Sequence

MAX_INPUT_LENGTH = 131
MAX_OUTPUT_BYTES = 1024


def expected_output(values: Sequence[int]) -> tuple[int, bytes]:
    """Return the encoded allocations, or the invalid-input result."""
    if not isinstance(values, (list, tuple)):
        return -1, b""
    if not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return -1, b""
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return -1, b""

    process_count, total_resources = values[:2]
    if not 0 <= process_count <= 64 or not 1 <= total_resources <= 1_000_000:
        return -1, b""
    if len(values) != 2 + 2 * process_count:
        return -1, b""

    processes: list[tuple[int, int]] = []
    for index in range(process_count):
        name_id, weight = values[2 + 2 * index : 4 + 2 * index]
        if not -(1 << 31) <= name_id < (1 << 31) or not 1 <= weight <= 1_000_000:
            return -1, b""
        processes.append((name_id, weight))

    if not processes:
        return 0, b""

    total_weight = sum(weight for _, weight in processes)
    payload = bytearray()
    for name_id, weight in processes:
        quotient = float(weight) / float(total_weight)
        share = quotient * float(total_resources)
        allocation = int(share)  # Java narrowing conversion truncates toward zero.
        payload.extend(struct.pack("<qq", name_id, allocation))
    return len(payload), bytes(payload)
