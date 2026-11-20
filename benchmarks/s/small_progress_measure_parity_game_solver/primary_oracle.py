"""Jurdziński's small progress-measure lifting for bounded parity games."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VERTICES = 8
MAX_EDGES = 20
MAX_PRIORITY = 5
MAX_VALID_INPUT_LENGTH = 58
MAX_PARSEABLE_INPUT_LENGTH = 59
WORKSPACE_BYTES = 2048

Measure = tuple[int, int, int] | None  # None is the greatest element TOP.


def parse_frame(values: Sequence[int] | None):
    if not isinstance(values, (list, tuple)) or not 6 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    vertex_count, edge_count = values[:2]
    if not 1 <= vertex_count <= MAX_VERTICES or not vertex_count <= edge_count <= MAX_EDGES:
        return None
    if len(values) != 2 + 2 * vertex_count + 2 * edge_count:
        return None
    owners: list[int] = []
    priorities: list[int] = []
    cursor = 2
    for _ in range(vertex_count):
        owner, priority = values[cursor:cursor + 2]
        cursor += 2
        if owner not in (0, 1) or not 0 <= priority <= MAX_PRIORITY:
            return None
        owners.append(owner)
        priorities.append(priority)
    adjacency = [[] for _ in range(vertex_count)]
    seen: set[tuple[int, int]] = set()
    for _ in range(edge_count):
        source, destination = values[cursor:cursor + 2]
        cursor += 2
        edge = (source, destination)
        if not 0 <= source < vertex_count or not 0 <= destination < vertex_count or edge in seen:
            return None
        seen.add(edge)
        adjacency[source].append(destination)
    if any(not successors for successors in adjacency):
        return None
    return vertex_count, owners, priorities, adjacency


def _measure_key(measure: Measure) -> tuple[int, tuple[int, int, int]]:
    return (1, (0, 0, 0)) if measure is None else (0, measure)


def _progress(measure: Measure, priority: int,
              bounds: tuple[int, int, int]) -> Measure:
    """Return the least paper-domain element satisfying Prog's prefix rule."""
    if measure is None:
        return None
    result = list(measure)
    included = (0 if priority < 1 else 1 if priority < 3 else 2 if priority < 5 else 3)
    for index in range(included, 3):
        result[index] = 0
    if priority % 2 == 0:
        return (result[0], result[1], result[2])
    for index in range(included - 1, -1, -1):
        if result[index] < bounds[index]:
            result[index] += 1
            for suffix in range(index + 1, included):
                result[suffix] = 0
            return (result[0], result[1], result[2])
        result[index] = 0
    return None


def expected_result(values: Sequence[int] | None) -> int:
    frame = parse_frame(values)
    if frame is None:
        return -1
    vertex_count, owners, priorities, adjacency = frame
    bounds = tuple(sum(priority == odd for priority in priorities)
                   for odd in (1, 3, 5))
    measures: list[Measure] = [(0, 0, 0) for _ in range(vertex_count)]

    while True:
        changed = False
        for vertex in range(vertex_count):
            edge_values = [_progress(measures[destination], priorities[vertex], bounds)
                           for destination in adjacency[vertex]]
            if owners[vertex] == 0:
                required = min(edge_values, key=_measure_key)
            else:
                required = max(edge_values, key=_measure_key)
            current = measures[vertex]
            lifted = max((current, required), key=_measure_key)
            if lifted != current:
                measures[vertex] = lifted
                changed = True
        if not changed:
            break

    return sum(1 << vertex for vertex, measure in enumerate(measures) if measure is not None)
