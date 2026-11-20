"""Heap-based Havel-Hakimi construction with an Erdős-Gallai check."""

from __future__ import annotations

import heapq
import struct
from collections.abc import Sequence

from .primary_oracle import (
    I64_MAX,
    I64_MIN,
    MAX_EDGES,
    MAX_INPUT_LENGTH,
    MAX_OUTPUT_BYTES,
    MAX_VERTICES,
)


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool) -> list[int] | None:
    if type(input_is_null) is not bool or input_is_null:
        return None
    if not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(type(value) is not int or value < I64_MIN or value > I64_MAX for value in values):
        return None
    declared = len(values) if input_length is None else input_length
    if type(declared) is not int or declared != len(values):
        return None
    n = values[0]
    if type(n) is not int or not 0 <= n <= MAX_VERTICES or len(values) != n + 1:
        return None
    degrees = list(values[1:])
    if any(type(degree) is not int or not 0 <= degree < n for degree in degrees):
        return None
    return degrees


def _erdos_gallai(degrees: list[int]) -> bool:
    ordered = sorted(degrees, reverse=True)
    n = len(ordered)
    if sum(ordered) % 2:
        return False
    prefix = [0]
    for degree in ordered:
        prefix.append(prefix[-1] + degree)
    for k in range(1, n + 1):
        right = k * (k - 1)
        right += sum(min(k, degree) for degree in ordered[k:])
        if prefix[k] > right:
            return False
    return True


def _construct_with_heap(degrees_input: list[int]) -> list[int] | None:
    n = len(degrees_input)
    if not _erdos_gallai(degrees_input):
        return None

    residual = degrees_input.copy()
    heap = [(-degree, vertex) for vertex, degree in enumerate(residual)]
    heapq.heapify(heap)
    edges: list[tuple[int, int]] = []
    while heap and -heap[0][0] > 0:
        negative_degree, hub = heapq.heappop(heap)
        degree = -negative_degree
        selected: list[tuple[int, int]] = []
        for _ in range(degree):
            if not heap:
                return None
            next_negative, neighbor = heapq.heappop(heap)
            neighbor_degree = -next_negative
            if neighbor_degree == 0:
                return None
            selected.append((neighbor, neighbor_degree - 1))
            edges.append((min(hub, neighbor), max(hub, neighbor)))
        for neighbor, new_degree in selected:
            heapq.heappush(heap, (-new_degree, neighbor))
    if any(negative_degree != 0 for negative_degree, _ in heap):
        return None
    words = [1, len(edges)]
    for left, right in edges:
        words.extend((left, right))
    return words


def _encode(words: list[int]) -> bytes:
    return b"".join(struct.pack("<q", word) for word in words)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    degrees = _parse(values, input_length, input_is_null)
    if degrees is None:
        return -1, b""
    words = _construct_with_heap(degrees)
    if words is None:
        words = [0]
    encoded = _encode(words)
    actual_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if type(output_is_null) is not bool or type(actual_capacity) is not int or actual_capacity < 0:
        return -2, b""
    if output_is_null or len(encoded) > actual_capacity:
        return -2, b""
    return len(encoded), encoded


def validate_realization(degrees: Sequence[int], words: Sequence[int]) -> bool:
    """Check an edge-list certificate independently of its construction trace."""
    if not _erdos_gallai(list(degrees)):
        return list(words) == [0]
    if len(words) < 2 or words[0] != 1:
        return False
    edge_count = words[1]
    if type(edge_count) is not int or not 0 <= edge_count <= MAX_EDGES:
        return False
    if len(words) != 2 + 2 * edge_count:
        return False
    counts = [0] * len(degrees)
    seen: set[tuple[int, int]] = set()
    for index in range(edge_count):
        left, right = words[2 + 2 * index:4 + 2 * index]
        if (type(left) is not int or type(right) is not int or left < 0
                or right >= len(degrees) or left >= right or (left, right) in seen):
            return False
        seen.add((left, right))
        counts[left] += 1
        counts[right] += 1
    return counts == list(degrees)
