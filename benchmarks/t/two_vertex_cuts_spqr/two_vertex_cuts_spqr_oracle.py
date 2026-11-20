"""Bounded split-component/SPQR oracle for weighted two-vertex cuts."""

from __future__ import annotations

from collections.abc import Sequence
from dataclasses import dataclass

MAX_VERTICES = 8
MAX_EDGES = 28
MAX_VALID_INPUT_LENGTH = 2 + MAX_VERTICES + 2 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MODULUS = 998244353
INVALID_RESULT = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1

SOURCE_BASIS = {
    "organization": "Library Checker problem proposal",
    "title": "Two-Vertex Cuts",
    "url": "https://github.com/yosupo06/library-checker-problems/issues/1427",
    "role": "problem_definition",
}


@dataclass(frozen=True)
class EdgeRef:
    u: int
    v: int
    real: bool
    pair_id: int = -1


@dataclass
class Piece:
    edges: list[EdgeRef]


def _connected(adjacency: list[list[bool]], n: int, removed: int) -> bool:
    start = 0
    while start == removed:
        start += 1
    seen = [False] * n
    seen[start] = True
    queue = [start]
    for vertex in queue:
        for other in range(n):
            if other != removed and adjacency[vertex][other] and not seen[other]:
                seen[other] = True
                queue.append(other)
    return sum(seen) == n - (removed >= 0)


def _valid_graph(n: int, edges: list[tuple[int, int]]) -> bool:
    adjacency = [[False] * n for _ in range(n)]
    for u, v in edges:
        if u == v or adjacency[u][v]:
            return False
        adjacency[u][v] = adjacency[v][u] = True
    return all(_connected(adjacency, n, removed) for removed in range(-1, n))


def _components_after_pair(piece: Piece, n: int, u: int, v: int) -> tuple[list[int], int]:
    component = [-1] * n
    component_count = 0
    for start in range(n):
        if start in (u, v) or component[start] >= 0:
            continue
        component[start] = component_count
        queue = [start]
        for vertex in queue:
            for edge in piece.edges:
                if edge.u in (u, v) or edge.v in (u, v):
                    continue
                if edge.u == vertex:
                    neighbor = edge.v
                elif edge.v == vertex:
                    neighbor = edge.u
                else:
                    continue
                if component[neighbor] < 0:
                    component[neighbor] = component_count
                    queue.append(neighbor)
        component_count += 1
    return component, component_count


def _split_choice(piece: Piece, n: int) -> tuple[int, int, list[int]] | None:
    """Return a deterministic proper split (poles, selected class IDs)."""
    edge_count = len(piece.edges)
    for u in range(n):
        for v in range(u + 1, n):
            component, component_count = _components_after_pair(piece, n, u, v)
            edge_class: list[int] = []
            direct_count = 0
            for edge in piece.edges:
                if (edge.u == u and edge.v == v) or (edge.u == v and edge.v == u):
                    edge_class.append(component_count + direct_count)
                    direct_count += 1
                else:
                    endpoint = edge.u if edge.u not in (u, v) else edge.v
                    edge_class.append(component[endpoint])
            class_count = component_count + direct_count
            sizes = [0] * class_count
            for class_id in edge_class:
                if not 0 <= class_id < class_count:
                    return None
                sizes[class_id] += 1

            for class_id, size in enumerate(sizes):
                if 2 <= size <= edge_count - 2:
                    return u, v, [class_id]
            if class_count >= 4 and class_count == edge_count and all(size == 1 for size in sizes):
                return u, v, [0, 1]
    return None


def _find(parent: list[int], item: int) -> int:
    while parent[item] != item:
        parent[item] = parent[parent[item]]
        item = parent[item]
    return item


def _union(parent: list[int], left: int, right: int) -> None:
    a = _find(parent, left)
    b = _find(parent, right)
    if a != b:
        parent[b] = a


def _piece_kind(piece: Piece) -> int:
    # 1 = S triangle, 2 = P triple bond, 3 = R rigid component.
    vertices = sorted({endpoint for edge in piece.edges for endpoint in (edge.u, edge.v)})
    if len(vertices) == 2 and len(piece.edges) >= 3:
        if all({edge.u, edge.v} == set(vertices) for edge in piece.edges):
            return 2
    if len(vertices) == 3 and len(piece.edges) == 3:
        pairs = {tuple(sorted((edge.u, edge.v))) for edge in piece.edges}
        if len(pairs) == 3:
            return 1
    return 3


def _bfs_component_count(adjacency: list[list[bool]], n: int, removed_u: int, removed_v: int) -> int:
    seen = [False] * n
    count = 0
    for start in range(n):
        if start in (removed_u, removed_v) or seen[start]:
            continue
        count += 1
        seen[start] = True
        queue = [start]
        for vertex in queue:
            for other in range(n):
                if other not in (removed_u, removed_v) and adjacency[vertex][other] and not seen[other]:
                    seen[other] = True
                    queue.append(other)
    return count


def _spqr_candidates(n: int, edges: list[tuple[int, int]]) -> set[tuple[int, int]] | None:
    pending = [Piece([EdgeRef(u, v, True) for u, v in edges])]
    leaves: list[Piece] = []
    pair_ends: list[tuple[int, int]] = []
    while pending:
        piece = pending.pop()
        choice = _split_choice(piece, n)
        if choice is None:
            leaves.append(piece)
            continue
        u, v, selected_classes = choice
        component, component_count = _components_after_pair(piece, n, u, v)
        classes: list[int] = []
        direct_count = 0
        for edge in piece.edges:
            if (edge.u == u and edge.v == v) or (edge.u == v and edge.v == u):
                classes.append(component_count + direct_count)
                direct_count += 1
            else:
                endpoint = edge.u if edge.u not in (u, v) else edge.v
                classes.append(component[endpoint])
        selected = set(selected_classes)
        left_edges: list[EdgeRef] = []
        right_edges: list[EdgeRef] = []
        pair_id = len(pair_ends)
        pair_ends.append((u, v))
        for edge, class_id in zip(piece.edges, classes, strict=True):
            (left_edges if class_id in selected else right_edges).append(edge)
        left_edges.append(EdgeRef(u, v, False, pair_id))
        right_edges.append(EdgeRef(u, v, False, pair_id))
        if len(left_edges) < 3 or len(right_edges) < 3:
            return None
        pending.append(Piece(right_edges))
        pending.append(Piece(left_edges))

    kinds = [_piece_kind(piece) for piece in leaves]
    first_leaf = [-1] * len(pair_ends)
    second_leaf = [-1] * len(pair_ends)
    occurrences = [0] * len(pair_ends)
    for leaf in range(len(leaves)):
        for edge in leaves[leaf].edges:
            if edge.real:
                continue
            if not 0 <= edge.pair_id < len(pair_ends):
                return None
            occurrences[edge.pair_id] += 1
            if occurrences[edge.pair_id] == 1:
                first_leaf[edge.pair_id] = leaf
            elif occurrences[edge.pair_id] == 2:
                second_leaf[edge.pair_id] = leaf
            else:
                return None
    if any(count != 2 for count in occurrences):
        return None

    parent = list(range(len(leaves)))
    for pair_id, (left, right) in enumerate(zip(first_leaf, second_leaf, strict=True)):
        if kinds[left] == kinds[right] and kinds[left] in (1, 2):
            _union(parent, left, right)

    candidates = set(pair_ends)
    for leaf in range(len(leaves)):
        root = _find(parent, leaf)
        if kinds[leaf] == 1 and root == leaf:
            in_group = [False] * n
            adjacent = [[False] * n for _ in range(n)]
            for member in range(len(leaves)):
                if _find(parent, member) != root:
                    continue
                for edge in leaves[member].edges:
                    if not edge.real:
                        pair = edge.pair_id
                        if _find(parent, first_leaf[pair]) == root and _find(parent, second_leaf[pair]) == root:
                            continue
                    in_group[edge.u] = in_group[edge.v] = True
                    adjacent[edge.u][edge.v] = adjacent[edge.v][edge.u] = True
            for u in range(n):
                for v in range(u + 1, n):
                    if in_group[u] and in_group[v] and not adjacent[u][v]:
                        candidates.add((u, v))
        elif kinds[leaf] == 2 and root == leaf:
            vertices = sorted({endpoint for member in range(len(leaves)) if _find(parent, member) == root
                               for edge in leaves[member].edges for endpoint in (edge.u, edge.v)})
            if len(vertices) != 2:
                return None
            candidates.add((vertices[0], vertices[1]))
    return candidates


def expected_result(
    values: Sequence[int] | None,
    *,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    """Run the bounded split decomposition and aggregate its cut candidates."""
    if type(input_is_null) is not bool:
        return INVALID_RESULT
    if input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH):
        return INVALID_RESULT
    if input_is_null:
        return INVALID_RESULT
    if not isinstance(values, (list, tuple)) or len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT

    n, m = values[:2]
    if not 3 <= n <= MAX_VERTICES or not 3 <= m <= MAX_EDGES:
        return INVALID_RESULT
    if len(values) != 2 + n + 2 * m:
        return INVALID_RESULT
    weights = values[2:2 + n]
    if any(not 0 <= weight <= 1_000_000 for weight in weights):
        return INVALID_RESULT
    edges: list[tuple[int, int]] = []
    offset = 2 + n
    for edge_id in range(m):
        u, v = values[offset + 2 * edge_id:offset + 2 * edge_id + 2]
        if not 0 <= u < n or not 0 <= v < n:
            return INVALID_RESULT
        edges.append((u, v))
    if not _valid_graph(n, edges):
        return INVALID_RESULT
    candidates = _spqr_candidates(n, edges)
    if candidates is None:
        return INVALID_RESULT
    adjacency = [[False] * n for _ in range(n)]
    for u, v in edges:
        adjacency[u][v] = adjacency[v][u] = True
    total = 0
    for u, v in candidates:
        component_count = _bfs_component_count(adjacency, n, u, v)
        total = (total + weights[u] * weights[v] * max(0, component_count - 1)) % MODULUS
    return total
