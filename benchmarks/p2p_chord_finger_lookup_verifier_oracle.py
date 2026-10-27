"""Independent scan-based verifier for static DOI272 Chord lookup traces."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_NODES = 16
MAX_BITS = 6
MAX_INPUT_LENGTH = 4 + MAX_NODES + MAX_NODES * MAX_BITS
MAX_OUTPUT_BYTES = 8 * MAX_NODES


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    invalid, output_error = -1, -2
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return invalid, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return invalid, b""
    if (not 4 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return invalid, b""
    width, n, current, key = values[:4]
    if not 1 <= width <= MAX_BITS or not 2 <= n <= min(MAX_NODES, 1 << width):
        return invalid, b""
    ring = 1 << width
    if not 0 <= current < n or not 0 <= key < ring or len(values) != 4 + n + n * width:
        return invalid, b""
    ids = values[4:4 + n]
    if any(not 0 <= node < ring for node in ids) or any(a >= b for a, b in zip(ids, ids[1:])):
        return invalid, b""
    table = values[4 + n:]
    # Verify every supplied pointer by a linear successor scan, not bisect.
    for node in range(n):
        for level in range(width):
            start_id = (ids[node] + (1 << level)) % ring
            successor = 0
            for index, candidate_id in enumerate(ids):
                if candidate_id >= start_id:
                    successor = index
                    break
            if table[node * width + level] != successor:
                return invalid, b""
    owner = 0
    for node in range(n):
        if ids[node] >= key:
            owner = node
            break
    path = [current]
    for _ in range(n):
        if current == owner:
            payload = struct.pack("<" + "q" * len(path), *(ids[index] for index in path))
            if output_is_null or capacity is not None and capacity < len(payload):
                return output_error, b""
            return len(payload), payload
        distance_to_owner = (ids[owner] - ids[current]) % ring
        next_node = -1
        next_distance = -1
        # The highest source finger in the non-passing clockwise interval wins.
        for level in range(width):
            candidate = table[current * width + level]
            distance = (ids[candidate] - ids[current]) % ring
            if 0 < distance <= distance_to_owner and distance > next_distance:
                next_node, next_distance = candidate, distance
        if next_node < 0 or next_node in path:
            return invalid, b""
        path.append(next_node)
        current = next_node
    return invalid, b""
