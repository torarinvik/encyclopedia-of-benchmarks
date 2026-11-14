"""Bounded Space-Saving reference with a deterministic minimum tie rule."""

from __future__ import annotations

from collections.abc import Sequence
import struct


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(input_is_null) is not bool or type(output_is_null) is not bool
            or input_is_null or not isinstance(values, (tuple, list))
            or not 2 <= len(values) <= 67
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values)):
        return -1, b""
    k, n = values[:2]
    if not 1 <= k <= 8 or not 0 <= n <= 64 or len(values) != 2+n:
        return -1, b""
    if any(not -1000 <= item <= 1000 for item in values[2:]):
        return -1, b""
    entries: dict[int, tuple[int, int]] = {}
    for item in values[2:]:
        if item in entries:
            count, error = entries[item]
            entries[item] = count+1, error
        elif len(entries) < k:
            entries[item] = 1, 0
        else:
            victim = min(entries, key=lambda candidate: (entries[candidate][0], candidate))
            minimum = entries[victim][0]
            del entries[victim]
            entries[item] = minimum+1, minimum
    words = [len(entries)]
    for item in sorted(entries):
        words.extend((item, *entries[item]))
    payload = struct.pack("<" + "q"*len(words), *words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
