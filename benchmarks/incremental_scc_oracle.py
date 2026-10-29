"""Independent recomputation oracle for the bounded incremental-SCC workload."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VERTICES = 8
MAX_EDGES = 32
MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES
INVALID_RESULT = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1

SOURCE_BASIS = [
    {
        "organization": "Library Checker",
        "title": "Strongly Connected Components (Incremental)",
        "url": "https://judge.yosupo.jp/",
        "role": "problem_taxonomy",
    },
    {
        "authors": "Valerie King and Garry Sagert",
        "title": "A Fully Dynamic Algorithm for Maintaining the Transitive Closure",
        "url": "https://doi.org/10.1006/jcss.2002.1883",
        "role": "primary_dynamic_transitive_closure_reference",
    },
    {
        "authors": "Thomas Schwentick, Nils Vortmeier, and Thomas Zeume",
        "title": "Sketches of Dynamic Complexity",
        "url": "https://sigmodrecord.org/2020/09/04/sketches-of-dynamic-complexity/",
        "role": "insertion_update_rule_exposition",
    },
]


def expected_result(
    values: Sequence[int] | None,
    *,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    """Recompute every prefix's transitive closure from its arcs."""
    if type(input_is_null) is not bool or input_is_null:
        return INVALID_RESULT
    if input_length is not None and (
        type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH
    ):
        return INVALID_RESULT
    if not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT

    vertex_count, edge_count = values[:2]
    if not 1 <= vertex_count <= MAX_VERTICES or not 0 <= edge_count <= MAX_EDGES:
        return INVALID_RESULT
    if len(values) != 2 + 2 * edge_count:
        return INVALID_RESULT
    edges: list[tuple[int, int]] = []
    for edge_id in range(edge_count):
        source, destination = values[2 + 2 * edge_id : 4 + 2 * edge_id]
        if not 0 <= source < vertex_count or not 0 <= destination < vertex_count:
            return INVALID_RESULT
        edges.append((source, destination))

    checksum = 0
    for prefix_length in range(1, edge_count + 1):
        reach = [[source == target for target in range(vertex_count)] for source in range(vertex_count)]
        for source, destination in edges[:prefix_length]:
            reach[source][destination] = True
        for middle in range(vertex_count):
            for source in range(vertex_count):
                if reach[source][middle]:
                    for target in range(vertex_count):
                        reach[source][target] = reach[source][target] or reach[middle][target]

        assigned = [False] * vertex_count
        component_count = 0
        for first in range(vertex_count):
            if assigned[first]:
                continue
            component_count += 1
            for vertex in range(first, vertex_count):
                if reach[first][vertex] and reach[vertex][first]:
                    assigned[vertex] = True
        checksum += prefix_length * component_count
    return checksum
