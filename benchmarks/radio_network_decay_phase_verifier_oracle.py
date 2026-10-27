"""Independent round-mask verifier for the bounded Decay phase profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= 75)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if (input_is_null or not isinstance(values, (tuple, list)) or not 3 <= len(values) <= 75
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    n, k, initial = values[:3]
    if not 2 <= n <= 8 or not 1 <= k <= 8 or len(values) != 3 + n + n * k:
        return -1, b""
    full = (1 << n) - 1
    if not 0 < initial <= full:
        return -1, b""
    neighbors = values[3:3 + n]
    for u, mask in enumerate(neighbors):
        if mask < 0 or mask & ~full or mask & (1 << u):
            return -1, b""
        for v in range(u + 1, n):
            if bool(mask & (1 << v)) != bool(neighbors[v] & (1 << u)):
                return -1, b""
    coins = values[3 + n:]
    if any(bit != 0 and bit != 1 for bit in coins):
        return -1, b""

    live = initial
    discovered = 0
    send_total = 0
    for round_index in range(k):
        send_total += live.bit_count()
        round_discovered = 0
        for receiver, incoming in enumerate(neighbors):
            if initial & (1 << receiver):
                continue
            if (incoming & live).bit_count() == 1:
                round_discovered |= 1 << receiver
        discovered |= round_discovered
        keep = 0
        for sender in range(n):
            if live & (1 << sender):
                if round_index + 1 < k and coins[sender * k + round_index] == 1:
                    keep |= 1 << sender
        live = keep

    payload = struct.pack("<qq", discovered, send_total)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
