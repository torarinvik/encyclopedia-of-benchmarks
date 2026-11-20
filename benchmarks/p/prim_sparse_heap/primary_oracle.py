"""Reference Prim implementation using an indexed binary min-heap."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VERTICES = 64
MAX_EDGES = 4096
MAX_ARCS = 2 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = 2 + 3 * MAX_EDGES
MAX_WEIGHT = (1 << 31) - 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
WORKSPACE_BYTES = 200704


def _parse(values: Sequence[int] | None) -> tuple[int, list[tuple[int, int, int]]] | int:
    if not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return -2
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return -2
    vertices, edge_count = values[0], values[1]
    if not 0 <= vertices <= MAX_VERTICES or not 0 <= edge_count <= MAX_EDGES:
        return -2
    if len(values) != 2 + 3 * edge_count or (vertices == 0 and edge_count != 0):
        return -2
    if vertices == 0:
        return 0, []
    arcs = []
    for offset in range(2, len(values), 3):
        origin, destination, weight = values[offset:offset + 3]
        if not 0 <= origin < vertices or not 0 <= destination < vertices:
            return -2
        if not 0 <= weight <= MAX_WEIGHT:
            return -2
        if origin != destination:
            arcs.append((origin, destination, weight))
            arcs.append((destination, origin, weight))
    return vertices, arcs


def expected_result(values: Sequence[int] | None) -> int:
    parsed = _parse(values)
    if isinstance(parsed, int):
        return parsed
    vertices, arcs = parsed
    if vertices == 0:
        return 0
    adjacency: list[list[tuple[int, int]]] = [[] for _ in range(vertices)]
    for origin, destination, weight in arcs:
        adjacency[origin].append((destination, weight))

    best = [0] * vertices
    valid = [False] * vertices
    selected = [False] * vertices
    heap: list[int] = []
    position = [-1] * vertices
    best[0] = 0
    valid[0] = True

    def before(left: int, right: int) -> bool:
        return (best[left], left) < (best[right], right)

    def exchange(first: int, second: int) -> None:
        heap[first], heap[second] = heap[second], heap[first]
        position[heap[first]] = first
        position[heap[second]] = second

    def push(vertex: int) -> None:
        position[vertex] = len(heap)
        heap.append(vertex)
        cursor = position[vertex]
        while cursor > 0:
            parent = (cursor - 1) // 2
            if not before(heap[cursor], heap[parent]):
                break
            exchange(cursor, parent)
            cursor = parent

    def pop_min() -> int:
        result = heap[0]
        position[result] = -1
        last = heap.pop()
        if heap:
            heap[0] = last
            position[last] = 0
            cursor = 0
            while 2 * cursor + 1 < len(heap):
                child = 2 * cursor + 1
                if child + 1 < len(heap) and before(heap[child + 1], heap[child]):
                    child += 1
                if not before(heap[child], heap[cursor]):
                    break
                exchange(cursor, child)
                cursor = child
        return result

    push(0)
    total = 0
    count = 0
    while heap:
        vertex = pop_min()
        if selected[vertex]:
            continue
        selected[vertex] = True
        count += 1
        total += best[vertex]
        for neighbor, weight in adjacency[vertex]:
            if selected[neighbor] or (valid[neighbor] and weight >= best[neighbor]):
                continue
            best[neighbor] = weight
            valid[neighbor] = True
            if position[neighbor] == -1:
                push(neighbor)
            else:
                cursor = position[neighbor]
                while cursor > 0:
                    parent = (cursor - 1) // 2
                    if not before(heap[cursor], heap[parent]):
                        break
                    exchange(cursor, parent)
                    cursor = parent
    return total if count == vertices else -1
