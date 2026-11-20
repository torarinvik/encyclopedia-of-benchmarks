"""Johnson SCC/blocked-set enumeration of elementary directed circuits."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 8
MAX_M = 24
MAX_CYCLES = 16_064
MAX_CYCLE_CODE = 43_046_480
MAX_HASH_SUM = 691_498_654_720
OUTPUT_BASE = 1_000_000_000_000
MAX_RESULT_UPPER_BOUND = 16_064_691_498_654_720
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_M
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
WORKSPACE_BYTES = 4096


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    n, edge_count = values[:2]
    if (not 1 <= n <= MAX_N or not 0 <= edge_count <= MAX_M
            or len(values) != 2 + 2 * edge_count):
        return None
    edges: list[tuple[int, int]] = []
    seen: set[tuple[int, int]] = set()
    for index in range(edge_count):
        source, destination = values[2 + 2 * index:4 + 2 * index]
        edge = source, destination
        if (not 0 <= source < n or not 0 <= destination < n
                or source == destination or edge in seen):
            return None
        seen.add(edge)
        edges.append(edge)
    return n, edges


def _strong_components(n: int, adjacency: Sequence[Sequence[int]],
                       reverse: Sequence[Sequence[int]], lower: int) -> list[list[int]]:
    visited = [False] * n
    finish_order: list[int] = []

    def finish(vertex: int) -> None:
        visited[vertex] = True
        for neighbor in adjacency[vertex]:
            if neighbor >= lower and not visited[neighbor]:
                finish(neighbor)
        finish_order.append(vertex)

    for vertex in range(lower, n):
        if not visited[vertex]:
            finish(vertex)

    visited = [False] * n
    components: list[list[int]] = []

    def collect(vertex: int, component: list[int]) -> None:
        visited[vertex] = True
        component.append(vertex)
        for neighbor in reverse[vertex]:
            if neighbor >= lower and not visited[neighbor]:
                collect(neighbor, component)

    for vertex in reversed(finish_order):
        if not visited[vertex]:
            component: list[int] = []
            collect(vertex, component)
            components.append(component)
    return components


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1
    n, edges = parsed
    adjacency: list[list[int]] = [[] for _ in range(n)]
    reverse: list[list[int]] = [[] for _ in range(n)]
    for source, destination in edges:
        adjacency[source].append(destination)
        reverse[destination].append(source)
    for neighbors in adjacency:
        neighbors.sort()
    for neighbors in reverse:
        neighbors.sort()

    cycle_count = 0
    code_sum = 0
    lower = 0
    while lower < n:
        cyclic_components = [component for component in
                             _strong_components(n, adjacency, reverse, lower)
                             if len(component) > 1]
        if not cyclic_components:
            break
        component = min(cyclic_components, key=min)
        root = min(component)
        members = set(component)
        blocked = [False] * n
        dependents = [set() for _ in range(n)]
        path: list[int] = []

        def unblock(vertex: int) -> None:
            blocked[vertex] = False
            while dependents[vertex]:
                waiting = dependents[vertex].pop()
                if blocked[waiting]:
                    unblock(waiting)

        def circuit(vertex: int) -> bool:
            nonlocal cycle_count, code_sum
            found = False
            path.append(vertex)
            blocked[vertex] = True
            for neighbor in adjacency[vertex]:
                if neighbor not in members:
                    continue
                if neighbor == root:
                    cycle_count += 1
                    code_sum += sum((item + 1) * (9 ** position)
                                    for position, item in enumerate(path))
                    found = True
                elif not blocked[neighbor] and circuit(neighbor):
                    found = True
            if found:
                unblock(vertex)
            else:
                for neighbor in adjacency[vertex]:
                    if neighbor in members:
                        dependents[neighbor].add(vertex)
            path.pop()
            return found

        circuit(root)
        lower = root + 1

    return cycle_count * OUTPUT_BASE + code_sum
