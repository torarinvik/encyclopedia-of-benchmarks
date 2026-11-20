"""Independent bitmask reference that advances one synchronized radio phase at a time."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT = 203


def _ceil_log2(value: int) -> int:
    exponent = 0
    power = 1
    while power < value:
        power *= 2
        exponent += 1
    return exponent


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
    if (input_is_null or not isinstance(values, (tuple, list)) or not 3 <= len(values) <= MAX_INPUT
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    n, source, delta = values[:3]
    if not 2 <= n <= 8 or not 0 <= source < n or not 2 <= delta <= 8:
        return -1, b""
    k = 2 * _ceil_log2(delta)
    t = _ceil_log2(2 * n)
    if len(values) != 3 + n + n * t * k:
        return -1, b""
    full = (1 << n) - 1
    neighbors = values[3:3 + n]
    for u, mask in enumerate(neighbors):
        if mask < 0 or mask & ~full or mask & (1 << u) or mask.bit_count() > delta:
            return -1, b""
        for v in range(u + 1, n):
            if bool(mask & (1 << v)) != bool(neighbors[v] & (1 << u)):
                return -1, b""
    coins = values[3 + n:]
    if any(bit != 0 and bit != 1 for bit in coins):
        return -1, b""

    informed = 1 << source
    reached_at = [-1] * n
    reached_at[source] = 0
    completed_calls = [0] * n
    send_total = 0
    phase_total = 0
    for phase in range(n * t):
        starters = informed
        for v in range(n):
            if completed_calls[v] >= t:
                starters &= ~(1 << v)
        if starters == 0:
            break
        live = starters
        fresh = 0
        for slot in range(k):
            send_total += live.bit_count()
            for receiver, incoming in enumerate(neighbors):
                bit = 1 << receiver
                if informed & bit or fresh & bit:
                    continue
                if (incoming & live).bit_count() == 1:
                    fresh |= bit
                    reached_at[receiver] = k * phase + slot
            keep = 0
            for sender in range(n):
                bit = 1 << sender
                if not live & bit:
                    continue
                tape_index = (sender * t + completed_calls[sender]) * k + slot
                if slot + 1 < k and coins[tape_index] == 1:
                    keep |= bit
            live = keep
        for vertex in range(n):
            if starters & (1 << vertex):
                completed_calls[vertex] += 1
        for vertex in range(n):
            bit = 1 << vertex
            if fresh & bit:
                informed |= bit
        phase_total = phase + 1

    payload = struct.pack("<" + "q" * (n + 3), n, phase_total, send_total, *reached_at)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
