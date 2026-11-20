"""Independent per-timestamp graph traversal reference."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import MAX_TIME, INVALID_RESULT, _read


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _read(values, input_is_null, input_length)
    if decoded is None:
        return INVALID_RESULT
    n, first_person, meetings = decoded
    informed = (1 << 0) | (1 << first_person)
    for time in range(1, MAX_TIME + 1):
        adjacency = [0] * n
        for u, v, event_time in meetings:
            if event_time == time:
                adjacency[u] |= 1 << v
                adjacency[v] |= 1 << u
        reached = informed
        frontier = informed
        while frontier:
            bit = frontier & -frontier
            frontier ^= bit
            node = bit.bit_length() - 1
            additions = adjacency[node] & ~reached
            reached |= additions
            frontier |= additions
        informed = reached
    return informed
