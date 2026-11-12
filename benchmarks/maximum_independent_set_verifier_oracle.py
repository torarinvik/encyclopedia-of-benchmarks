"""Independent exhaustive-subset oracle for bounded MIS workload fixtures."""

from __future__ import annotations

from typing import Sequence

MAX_N = 22
MAX_EDGES = MAX_N * (MAX_N - 1) // 2
MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES + 1


def expected_result(values: Sequence[int]) -> int:
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1
    n, edge_count = values[0], values[1]
    if (not 0 <= n <= MAX_N or not 0 <= edge_count <= n * (n - 1) // 2
            or len(values) != 2 + 2 * edge_count):
        return -1
    adjacency = [0] * n
    seen: set[tuple[int, int]] = set()
    for offset in range(2, len(values), 2):
        left, right = values[offset:offset + 2]
        if not (0 <= left < n and 0 <= right < n and left != right):
            return -1
        edge = (min(left, right), max(left, right))
        if edge in seen:
            return -1
        seen.add(edge)
        adjacency[left] |= 1 << right
        adjacency[right] |= 1 << left
    best = 0
    for subset in range(1 << len(adjacency)):
        size = subset.bit_count()
        if size <= best:
            continue
        remaining = subset
        independent = True
        while remaining:
            bit = remaining & -remaining
            vertex = bit.bit_length() - 1
            if adjacency[vertex] & subset:
                independent = False
                break
            remaining &= ~bit
        if independent:
            best = size
    return best
