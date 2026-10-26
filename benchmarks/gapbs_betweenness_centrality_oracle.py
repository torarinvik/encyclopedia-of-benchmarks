"""Independent shortest-path-enumeration oracle for GAPBS Brandes BC."""
from __future__ import annotations

from collections import deque
from fractions import Fraction
import struct
from collections.abc import Sequence

MAX_N = 8
INVALID_RESULT = -1


def _f32(value: float) -> float:
    return struct.unpack("<f", struct.pack("<f", value))[0]


def _parse(values: Sequence[int] | None) -> tuple[list[list[int]], list[int]] | None:
    if not isinstance(values, (list, tuple)) or len(values) < 12 or len(values) > 74:
        return None
    if any(type(value) is not int for value in values):
        return None
    n, source_count = values[0], values[1]
    if not 3 <= n <= MAX_N or not 1 <= source_count <= n:
        return None
    if len(values) != 2 + source_count + n * n:
        return None
    sources = list(values[2:2 + source_count])
    if any(source < 0 or source >= n for source in sources) or len(set(sources)) != source_count:
        return None
    raw = values[2 + source_count:]
    graph = [list(raw[row * n:(row + 1) * n]) for row in range(n)]
    for u in range(n):
        for v in range(n):
            if graph[u][v] not in (0, 1) or (u == v and graph[u][v] != 0):
                return None
            if graph[u][v] != graph[v][u]:
                return None
    return graph, sources


def _source_dependency(graph: list[list[int]], source: int) -> list[Fraction]:
    """Enumerate each target's shortest paths and distribute its unit weight."""
    n = len(graph)
    distance = [-1] * n
    distance[source] = 0
    queue = deque([source])
    while queue:
        u = queue.popleft()
        for v in range(n):
            if graph[u][v] and distance[v] == -1:
                distance[v] = distance[u] + 1
                queue.append(v)

    dependencies = [Fraction(0) for _ in range(n)]
    for target in range(n):
        if target == source or distance[target] < 0:
            continue
        paths: list[list[int]] = []

        def enumerate_backwards(v: int, reverse_path: list[int]) -> None:
            if v == source:
                paths.append(list(reversed(reverse_path + [source])))
                return
            for predecessor in range(n):
                if (graph[predecessor][v] and
                        distance[predecessor] == distance[v] - 1):
                    enumerate_backwards(predecessor, reverse_path + [v])

        enumerate_backwards(target, [])
        share = Fraction(1, len(paths))
        for path in paths:
            for vertex in path[:-1]:
                dependencies[vertex] += share
    return dependencies


def expected_result(values: Sequence[int] | None) -> int:
    parsed = _parse(values)
    if parsed is None:
        return INVALID_RESULT
    graph, sources = parsed
    scores = [_f32(0.0) for _ in graph]
    for source in sources:
        dependency = _source_dependency(graph, source)
        for vertex, exact_value in enumerate(dependency):
            source_score = _f32(float(exact_value))
            scores[vertex] = _f32(scores[vertex] + source_score)

    biggest = max(scores)
    if biggest <= 0.0:
        return INVALID_RESULT
    total = 0
    for vertex, score in enumerate(scores):
        normalized = _f32(score / biggest)
        qscore = int(float(normalized) * 1000.0 + 0.5)
        total += (vertex + 1) * qscore
    return total
