"""Bounded deterministic Boykov–Kolmogorov max-flow reference."""

from __future__ import annotations

from collections import deque
from collections.abc import Sequence

MIN_VERTICES = 2
MAX_VERTICES = 8
MIN_EDGES = 0
MAX_EDGES = 16
MIN_CAPACITY = 0
MAX_CAPACITY = 15
MAX_VALID_INPUT_LENGTH = 4 + 3 * MAX_EDGES
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_RESULT = MAX_EDGES * MAX_CAPACITY

FREE = 0
SOURCE_TREE = 1
SINK_TREE = 2


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int, int, list[tuple[int, int, int]]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 4 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))):
        return None
    vertex_count, edge_count, source, sink = values[:4]
    if (not MIN_VERTICES <= vertex_count <= MAX_VERTICES
            or not MIN_EDGES <= edge_count <= MAX_EDGES
            or not 0 <= source < vertex_count or not 0 <= sink < vertex_count
            or source == sink or len(values) != 4 + 3 * edge_count):
        return None
    edges: list[tuple[int, int, int]] = []
    for offset in range(4, len(values), 3):
        left, right, capacity = values[offset:offset + 3]
        if (not 0 <= left < vertex_count or not 0 <= right < vertex_count
                or left == right or not MIN_CAPACITY <= capacity <= MAX_CAPACITY):
            return None
        edges.append((left, right, capacity))
    return vertex_count, source, sink, edges


def _tree_capacity(residual: list[list[int]], tree: int,
                   parent: int, child: int) -> int:
    return (residual[parent][child] if tree == SOURCE_TREE
            else residual[child][parent])


def _has_terminal_origin(vertex: int, tree_kind: int, blocked: int,
                         source: int, sink: int, tree: list[int],
                         parent: list[int], residual: list[list[int]],
                         vertex_count: int) -> bool:
    root = source if tree_kind == SOURCE_TREE else sink
    seen = [False] * vertex_count
    current = vertex
    while True:
        if current == blocked or seen[current] or tree[current] != tree_kind:
            return False
        if current == root:
            return True
        seen[current] = True
        next_vertex = parent[current]
        if next_vertex < 0 or next_vertex >= vertex_count:
            return False
        if _tree_capacity(residual, tree_kind, next_vertex, current) <= 0:
            return False
        current = next_vertex


def _remove_active(vertex: int, active: deque[int], is_active: list[bool]) -> None:
    if not is_active[vertex]:
        return
    kept = [candidate for candidate in active if candidate != vertex]
    active.clear()
    active.extend(kept)
    is_active[vertex] = False


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1
    vertex_count, source, sink, edges = parsed
    residual = [[0] * vertex_count for _ in range(vertex_count)]
    for left, right, capacity in edges:
        residual[left][right] += capacity

    tree = [FREE] * vertex_count
    parent = [-1] * vertex_count
    tree[source] = SOURCE_TREE
    tree[sink] = SINK_TREE
    active: deque[int] = deque((source, sink))
    is_active = [False] * vertex_count
    is_active[source] = True
    is_active[sink] = True
    total_flow = 0

    while active:
        bridge_source = -1
        bridge_sink = -1
        found_bridge = False
        while active:
            vertex = active.popleft()
            is_active[vertex] = False
            kind = tree[vertex]
            for neighbor in range(vertex_count):
                capacity = _tree_capacity(residual, kind, vertex, neighbor)
                if capacity <= 0:
                    continue
                if tree[neighbor] == FREE:
                    tree[neighbor] = kind
                    parent[neighbor] = vertex
                    active.append(neighbor)
                    is_active[neighbor] = True
                elif tree[neighbor] != kind:
                    if kind == SOURCE_TREE:
                        bridge_source, bridge_sink = vertex, neighbor
                    else:
                        bridge_source, bridge_sink = neighbor, vertex
                    found_bridge = True
                    if not is_active[vertex]:
                        active.append(vertex)
                        is_active[vertex] = True
                    break
            if found_bridge:
                break
        if not found_bridge:
            break

        path_from: list[int] = []
        path_to: list[int] = []
        reversed_source_path: list[tuple[int, int]] = []
        current = bridge_source
        while current != source:
            previous = parent[current]
            if previous < 0:
                return -1
            reversed_source_path.append((previous, current))
            current = previous
        for left, right in reversed(reversed_source_path):
            path_from.append(left)
            path_to.append(right)
        path_from.append(bridge_source)
        path_to.append(bridge_sink)
        current = bridge_sink
        while current != sink:
            next_vertex = parent[current]
            if next_vertex < 0:
                return -1
            path_from.append(current)
            path_to.append(next_vertex)
            current = next_vertex

        bottleneck = min(residual[left][right]
                         for left, right in zip(path_from, path_to))
        if bottleneck <= 0:
            return -1
        for left, right in zip(path_from, path_to):
            residual[left][right] -= bottleneck
            residual[right][left] += bottleneck
        total_flow += bottleneck

        orphans: deque[int] = deque()
        is_orphan = [False] * vertex_count
        for left, right in zip(path_from, path_to):
            if residual[left][right] != 0:
                continue
            if (tree[left] == SOURCE_TREE and tree[right] == SOURCE_TREE
                    and parent[right] == left):
                parent[right] = -1
                if not is_orphan[right]:
                    orphans.append(right)
                    is_orphan[right] = True
            elif (tree[left] == SINK_TREE and tree[right] == SINK_TREE
                    and parent[left] == right):
                parent[left] = -1
                if not is_orphan[left]:
                    orphans.append(left)
                    is_orphan[left] = True

        while orphans:
            orphan = orphans.popleft()
            is_orphan[orphan] = False
            kind = tree[orphan]
            if kind == FREE:
                continue
            replacement = -1
            for candidate in range(vertex_count):
                if (candidate != orphan and tree[candidate] == kind
                        and _tree_capacity(residual, kind, candidate, orphan) > 0
                        and _has_terminal_origin(
                            candidate, kind, orphan, source, sink, tree, parent,
                            residual, vertex_count)):
                    replacement = candidate
                    break
            if replacement >= 0:
                parent[orphan] = replacement
                continue

            for neighbor in range(vertex_count):
                if tree[neighbor] != kind:
                    continue
                if _tree_capacity(residual, kind, neighbor, orphan) > 0:
                    if not is_active[neighbor]:
                        active.append(neighbor)
                        is_active[neighbor] = True
                if parent[neighbor] == orphan:
                    parent[neighbor] = -1
                    if not is_orphan[neighbor]:
                        orphans.append(neighbor)
                        is_orphan[neighbor] = True
            tree[orphan] = FREE
            parent[orphan] = -1
            _remove_active(orphan, active, is_active)

    return total_flow
