"""Heap-based independent Space-Saving verifier with frequency bounds."""

from __future__ import annotations

from collections import Counter
from collections.abc import Sequence
import heapq
import struct


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(input_is_null) is not bool or type(output_is_null) is not bool
            or input_is_null or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= 67
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or any(type(v) is not int or v < -(1 << 63) or v >= 1 << 63 for v in values)):
        return -1, b""
    k, count = values[:2]
    if not 1 <= k <= 8 or not 0 <= count <= 64 or len(values) != count+2:
        return -1, b""
    stream = values[2:]
    if any(item < -1000 or item > 1000 for item in stream):
        return -1, b""
    counters: dict[int, tuple[int, int]] = {}
    heap: list[tuple[int, int]] = []
    for item in stream:
        if item in counters:
            estimate, error = counters[item]
            counters[item] = estimate+1, error
        elif len(counters) < k:
            counters[item] = 1, 0
        else:
            while heap and (heap[0][1] not in counters or counters[heap[0][1]][0] != heap[0][0]):
                heapq.heappop(heap)
            minimum, victim = heapq.heappop(heap)
            del counters[victim]
            counters[item] = minimum+1, minimum
        heapq.heappush(heap, (counters[item][0], item))
    exact = Counter(stream)
    for item, (estimate, error) in counters.items():
        if not estimate-error <= exact[item] <= estimate:
            raise ValueError("Space-Saving counter violates its frequency bounds")
    words = [len(counters)]
    for item in sorted(counters):
        estimate, error = counters[item]
        words.extend((item, estimate, error))
    payload = struct.pack("<" + "q"*len(words), *words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
