"""Canonical static-ring finger-table lookup oracle for the DOI272 profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_NODES = 16
MAX_BITS = 6
MAX_INPUT_LENGTH = 4 + MAX_NODES + MAX_NODES * MAX_BITS
MAX_OUTPUT_BYTES = 8 * MAX_NODES
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _decode(values: Sequence[int] | None) -> tuple[int, int, int, list[int], list[int]] | None:
    if (not isinstance(values, (list, tuple)) or not 4 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    bits, count, start, key = values[:4]
    if not 1 <= bits <= MAX_BITS or not 2 <= count <= min(MAX_NODES, 1 << bits):
        return None
    if not 0 <= start < count or not 0 <= key < 1 << bits:
        return None
    if len(values) != 4 + count + count * bits:
        return None
    ids = list(values[4:4 + count])
    if (any(not 0 <= node < 1 << bits for node in ids)
            or any(ids[i] >= ids[i + 1] for i in range(count - 1))):
        return None
    fingers = list(values[4 + count:])
    for node_index, node_id in enumerate(ids):
        for level in range(bits):
            target = (node_id + (1 << level)) % (1 << bits)
            expected = next((i for i, candidate in enumerate(ids) if candidate >= target), 0)
            if fingers[node_index * bits + level] != expected:
                return None
    return bits, count, start, ids, fingers


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
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    decoded = _decode(values)
    if decoded is None:
        return INVALID_RESULT, b""
    bits, count, start, ids, fingers = decoded
    key = values[3]
    # Recompute the owner and route using the exact identifier-space modulus.
    owner = next((i for i, node_id in enumerate(ids) if node_id >= key), 0)
    route = [start]
    current = start
    ring = 1 << bits
    for _ in range(count):
        if current == owner:
            payload = struct.pack("<" + "q" * len(route), *(ids[i] for i in route))
            if output_is_null or capacity is not None and capacity < len(payload):
                return OUTPUT_ERROR, b""
            return len(payload), payload
        target_distance = (ids[owner] - ids[current]) % ring
        chosen = -1
        progress_max = 0
        for level in reversed(range(bits)):
            candidate = fingers[current * bits + level]
            progress = (ids[candidate] - ids[current]) % ring
            if 0 < progress <= target_distance:
                chosen = candidate
                progress_max = progress
                break
        if chosen < 0 or chosen in route or progress_max == 0:
            return INVALID_RESULT, b""
        route.append(chosen)
        current = chosen
    return INVALID_RESULT, b""
