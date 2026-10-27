"""Primary direct-simulation oracle for one bounded radio-network Decay phase."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_K = 8
MAX_INPUT = 75
MAX_OUTPUT_BYTES = 16


def _decode(values: Sequence[int] | None):
    if (not isinstance(values, (tuple, list)) or not 3 <= len(values) <= MAX_INPUT
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, k, initial = values[:3]
    if not 2 <= n <= MAX_N or not 1 <= k <= MAX_K or len(values) != 3 + n + n * k:
        return None
    full = (1 << n) - 1
    if not 0 < initial <= full:
        return None
    adjacency = list(values[3:3 + n])
    for vertex, neighbors in enumerate(adjacency):
        if neighbors < 0 or neighbors & ~full or neighbors & (1 << vertex):
            return None
        for other in range(n):
            if bool(neighbors & (1 << other)) != bool(adjacency[other] & (1 << vertex)):
                return None
    tape = list(values[3 + n:])
    if any(bit not in (0, 1) for bit in tape):
        return None
    return n, k, initial, adjacency, tape


def _solve(parsed):
    n, k, initial, adjacency, tape = parsed
    active = [bool(initial & (1 << vertex)) for vertex in range(n)]
    newly_informed = 0
    transmissions = 0
    for slot in range(k):
        senders = [vertex for vertex in range(n) if active[vertex]]
        transmissions += len(senders)
        received = 0
        for vertex in range(n):
            if initial & (1 << vertex):
                continue
            count = sum(1 for sender in senders if adjacency[sender] & (1 << vertex))
            if count == 1:
                received |= 1 << vertex
        newly_informed |= received
        for sender in senders:
            if tape[sender * k + slot] == 0 or slot + 1 == k:
                active[sender] = False
    return newly_informed, transmissions


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _decode(values)
    if parsed is None:
        return -1, b""
    newly_informed, transmissions = _solve(parsed)
    payload = struct.pack("<qq", newly_informed, transmissions)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
