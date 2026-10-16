"""Bounded oracle for the pinned JavaScript graph-density formula."""

from __future__ import annotations

INVALID_RESULT = -1e300
MAX_NODE_COUNT = 100_000
MAX_INPUT_LENGTH = 3


def expected_result(values: tuple[int, ...] | list[int]) -> float:
    if (not isinstance(values, (tuple, list)) or len(values) != MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return INVALID_RESULT
    node_count, edge_count, directed = values
    if not 2 <= node_count <= MAX_NODE_COUNT or directed not in (0, 1):
        return INVALID_RESULT
    maximum_edges = node_count * (node_count - 1)
    if directed == 0:
        maximum_edges //= 2
    if not 0 <= edge_count <= maximum_edges:
        return INVALID_RESULT
    factor = 1.0 if directed == 1 else 2.0
    return (factor * edge_count) / (node_count * (node_count - 1))
