"""Primary phase-by-phase reference for the bounded BGI broadcast schedule."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_INPUT = 203
MAX_OUTPUT_BYTES = 88
WORKSPACE_BYTES = 2048


def _ceil_log2(value: int) -> int:
    power = 1
    exponent = 0
    while power < value:
        power <<= 1
        exponent += 1
    return exponent


def _decode(values: Sequence[int] | None):
    if (not isinstance(values, (tuple, list)) or not 3 <= len(values) <= MAX_INPUT
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, source, delta = values[:3]
    if not 2 <= n <= MAX_N or not 0 <= source < n or not 2 <= delta <= 8:
        return None
    k = 2 * _ceil_log2(delta)
    # The bounded profile fixes N=n and epsilon=1/2.
    t = _ceil_log2(2 * n)
    if len(values) != 3 + n + n * t * k:
        return None
    full = (1 << n) - 1
    adjacency = list(values[3:3 + n])
    for vertex, neighbors in enumerate(adjacency):
        if neighbors < 0 or neighbors & ~full or neighbors & (1 << vertex):
            return None
        if neighbors.bit_count() > delta:
            return None
        for other in range(n):
            if bool(neighbors & (1 << other)) != bool(adjacency[other] & (1 << vertex)):
                return None
    tape = list(values[3 + n:])
    if any(bit not in (0, 1) for bit in tape):
        return None
    return n, source, k, t, adjacency, tape


def _solve(parsed):
    n, source, k, t, adjacency, tape = parsed
    informed = [False] * n
    informed[source] = True
    first_slot = [-1] * n
    first_slot[source] = 0
    calls = [0] * n
    transmissions = 0
    phases = 0

    # Each nonempty global phase executes at least one of the at most n*t calls.
    for phase in range(n * t):
        starters = [v for v in range(n) if informed[v] and calls[v] < t]
        if not starters:
            break
        informed_at_start = informed[:]
        active = [False] * n
        for vertex in starters:
            active[vertex] = True
        newly = [False] * n
        for slot in range(k):
            senders = [v for v in range(n) if active[v]]
            transmissions += len(senders)
            for receiver in range(n):
                if informed_at_start[receiver] or newly[receiver]:
                    continue
                count = sum(1 for sender in senders
                            if adjacency[sender] & (1 << receiver))
                if count == 1:
                    newly[receiver] = True
                    first_slot[receiver] = k * phase + slot
            for sender in senders:
                tape_index = (sender * t + calls[sender]) * k + slot
                if slot + 1 == k or tape[tape_index] == 0:
                    active[sender] = False
        for vertex in starters:
            calls[vertex] += 1
        for vertex in range(n):
            if newly[vertex]:
                informed[vertex] = True
        phases = phase + 1

    return [n, phases, transmissions, *first_slot]


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
    payload = struct.pack("<" + "q" * (parsed[0] + 3), *_solve(parsed))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
