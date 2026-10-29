"""Exact-length dynamic-programming oracle for bounded directed walk rankings."""

from __future__ import annotations

from bisect import insort
from collections.abc import Sequence
import struct

MAX_VERTICES = 6
MAX_EDGES = 12
MAX_K = 8
MAX_WEIGHT = 1000
MAX_INPUT_LENGTH = 41
MAX_OUTPUT_BYTES = 8 * MAX_K
MAX_WALK_EDGES = MAX_VERTICES * MAX_K - 1


def expected_output(
        values: Sequence[int] | None,
        capacity: int | None = None,
        output_is_null: bool = False,
        input_is_null: bool = False,
        input_length: int | None = None,
) -> tuple[int, bytes]:
    """Rank walks by length, counting duplicate arcs and repeated vertices/edges."""
    if (
        type(output_is_null) is not bool
        or type(input_is_null) is not bool
        or (capacity is not None and (type(capacity) is not int or capacity < 0))
        or (input_length is not None
            and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH))
        or (input_is_null and values not in (None, [], ()))
    ):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if (
        len(values) < 5
        or len(values) > MAX_INPUT_LENGTH
        or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)
        or (input_length is not None and input_length != len(values))
    ):
        return -1, b""

    vertex_count, edge_count, source, target, k = values[:5]
    if not 1 <= vertex_count <= MAX_VERTICES or not 0 <= edge_count <= MAX_EDGES:
        return -1, b""
    if not 1 <= k <= MAX_K or not 0 <= source < vertex_count or not 0 <= target < vertex_count:
        return -1, b""
    if len(values) != 5 + 3 * edge_count:
        return -1, b""

    outgoing: list[list[tuple[int, int]]] = [[] for _ in range(vertex_count)]
    for edge_index in range(edge_count):
        edge_source, edge_target, weight = values[5 + 3 * edge_index:8 + 3 * edge_index]
        if (not 0 <= edge_source < vertex_count or not 0 <= edge_target < vertex_count
                or not 0 <= weight <= MAX_WEIGHT):
            return -1, b""
        outgoing[edge_source].append((edge_target, weight))

    if output_is_null or (capacity is not None and capacity < 8 * k):
        return -2, b""

    # Any walk with at least K*N edges visits some vertex at least K+1 times.
    # Replacing each prefix ending at those visits with the final suffix yields
    # K+1 distinct walks no more expensive than it, so such a walk cannot rank
    # among the first K. Keeping K costs for each exact length is also safe:
    # K cheaper/equal prefixes can all be extended by the same suffix.
    current: list[list[int]] = [[] for _ in range(vertex_count)]
    current[source] = [0]
    target_costs: list[int] = []
    for depth in range(MAX_WALK_EDGES + 1):
        target_costs.extend(current[target])
        if depth == MAX_WALK_EDGES:
            break
        following: list[list[int]] = [[] for _ in range(vertex_count)]
        for vertex, costs in enumerate(current):
            for cost in costs:
                for next_vertex, weight in outgoing[vertex]:
                    bucket = following[next_vertex]
                    insort(bucket, cost + weight)
                    if len(bucket) > k:
                        bucket.pop()
        current = following

    answers = sorted(target_costs)[:k]
    answers.extend([-1] * (k - len(answers)))
    payload = struct.pack(f"<{k}q", *answers)
    return len(payload), payload
