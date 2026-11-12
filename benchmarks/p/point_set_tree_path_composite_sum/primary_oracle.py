"""Incremental rake/compress top-tree oracle for the arbitrary-root task."""

from __future__ import annotations

from collections.abc import Sequence
from dataclasses import dataclass

MOD = 998244353
MAX_N = 16
MAX_Q = 32
MAX_INPUT = 2 + MAX_N + 4 * (MAX_N - 1) + 5 * MAX_Q
MAX_OUTPUT_BYTES = 8 * MAX_Q
MAX_CLUSTER_NODES = max(1, 5 * MAX_N - 5)
WORKSPACE_BYTES = 16384
INVALID_RESULT = -1
OUTPUT_ERROR = -2

IDENTITY = (1, 0)
VERTEX = 0
EDGE = 1
RAKE = 2
BRANCH = 3
ATTACH = 4
COMPRESS = 5


@dataclass
class _Cluster:
    kind: int
    a: int = -1
    b: int = -1
    parent: int = -1
    shared: int = -1
    boundary0: int = -1
    boundary1: int = -1
    boundary_count: int = 1
    has0: bool = False
    has1: bool = False
    mask: int = 0
    count: int = 0
    sum0: int = 0
    sum1: int = 0
    forward: tuple[int, int] = IDENTITY
    reverse: tuple[int, int] = IDENTITY
    edge_id: int = -1


@dataclass
class _Context:
    sum0: int = 0
    count0: int = 0
    sum1: int = 0
    count1: int = 0


def _compose(outer: tuple[int, int], inner: tuple[int, int]) -> tuple[int, int]:
    return (outer[0] * inner[0] % MOD,
            (outer[0] * inner[1] + outer[1]) % MOD)


def _apply(mapping: tuple[int, int], total: int, count: int) -> int:
    return (mapping[0] * total + mapping[1] * count) % MOD


def _boundary_index(node: _Cluster, vertex: int) -> int:
    if node.boundary0 == vertex:
        return 0
    if node.boundary_count == 2 and node.boundary1 == vertex:
        return 1
    return -1


def _has(node: _Cluster, vertex: int) -> bool:
    index = _boundary_index(node, vertex)
    if index == 0:
        return node.has0
    if index == 1:
        return node.has1
    return False


def _sum_at(node: _Cluster, vertex: int) -> int:
    return node.sum0 if _boundary_index(node, vertex) == 0 else node.sum1


def _map_at(node: _Cluster, source: int, target: int) -> tuple[int, int]:
    if source == target:
        return IDENTITY
    if node.boundary_count != 2:
        return IDENTITY
    return node.forward if (node.boundary0, node.boundary1) == (source, target) else node.reverse


def _new_vertex(nodes: list[_Cluster], vertex: int,
                vertex_values: list[int]) -> int:
    node_id = len(nodes)
    nodes.append(_Cluster(VERTEX, boundary0=vertex, has0=True,
                          mask=1 << vertex, count=1,
                          sum0=vertex_values[vertex]))
    return node_id


def _new_edge(nodes: list[_Cluster], edge_id: int,
              edge_u: list[int], edge_v: list[int],
              edge_map: list[tuple[int, int]]) -> int:
    node_id = len(nodes)
    u, v = edge_u[edge_id], edge_v[edge_id]
    mapping = edge_map[edge_id]
    nodes.append(_Cluster(EDGE, boundary0=u, boundary1=v,
                          boundary_count=2, forward=mapping,
                          reverse=mapping, edge_id=edge_id))
    return node_id


def _merge(nodes: list[_Cluster], kind: int, a_id: int, b_id: int,
           shared: int, vertex_values: list[int]) -> int:
    a, b = nodes[a_id], nodes[b_id]
    a_other = a.boundary1 if a.boundary_count == 2 and a.boundary0 == shared else a.boundary0
    b_other = b.boundary1 if b.boundary_count == 2 and b.boundary0 == shared else b.boundary0
    if kind == RAKE:
        boundaries = (shared,)
    elif kind == BRANCH:
        boundaries = (a_other,)
    elif kind == ATTACH:
        boundaries = (a.boundary0, a.boundary1)
    else:
        boundaries = (a_other, b_other)
    parent_id = len(nodes)
    parent = _Cluster(kind, a_id, b_id, -1, shared,
                      boundaries[0], boundaries[-1], len(boundaries))
    a.parent = parent_id
    b.parent = parent_id
    nodes.append(parent)
    _recalculate(nodes, parent_id, vertex_values)
    return parent_id


def _recalculate(nodes: list[_Cluster], parent_id: int,
                 vertex_values: list[int]) -> None:
    parent = nodes[parent_id]
    if parent.kind == VERTEX:
        parent.count = 1
        parent.mask = 1 << parent.boundary0
        parent.sum0 = vertex_values[parent.boundary0]
        return
    if parent.kind == EDGE:
        return
    a = nodes[parent.a]
    b = nodes[parent.b]
    shared = parent.shared
    boundaries = ((parent.boundary0,) if parent.boundary_count == 1
                  else (parent.boundary0, parent.boundary1))
    overlap = _has(a, shared) and _has(b, shared)
    duplicate = vertex_values[shared] if overlap else 0
    duplicate_count = int(overlap)
    parent.count = a.count + b.count - duplicate_count
    parent.mask = a.mask | b.mask
    for index, boundary in enumerate(boundaries):
        if boundary == shared:
            total = (_sum_at(a, shared) + _sum_at(b, shared) - duplicate) % MOD
        elif _boundary_index(a, boundary) >= 0:
            sibling_total = (_sum_at(b, shared) - duplicate) % MOD
            parent_map = _map_at(a, boundary, shared)
            total = (_sum_at(a, boundary) +
                     _apply(parent_map, sibling_total, b.count - duplicate_count)) % MOD
        else:
            sibling_total = (_sum_at(a, shared) - duplicate) % MOD
            parent_map = _map_at(b, boundary, shared)
            total = (_sum_at(b, boundary) +
                     _apply(parent_map, sibling_total, a.count - duplicate_count)) % MOD
        if index == 0:
            parent.sum0 = total
            parent.has0 = _has(a, boundary) or _has(b, boundary)
        else:
            parent.sum1 = total
            parent.has1 = _has(a, boundary) or _has(b, boundary)

    if len(boundaries) == 2:
        p, q = boundaries
        a_has_p, a_has_q = _boundary_index(a, p) >= 0, _boundary_index(a, q) >= 0
        b_has_p, b_has_q = _boundary_index(b, p) >= 0, _boundary_index(b, q) >= 0
        if a_has_p and a_has_q:
            parent.forward = _map_at(a, p, q)
            parent.reverse = _map_at(a, q, p)
        elif b_has_p and b_has_q:
            parent.forward = _map_at(b, p, q)
            parent.reverse = _map_at(b, q, p)
        else:
            parent.forward = _compose(_map_at(a, p, shared), _map_at(b, shared, q))
            parent.reverse = _compose(_map_at(b, q, shared), _map_at(a, shared, p))


def _make_rake(nodes: list[_Cluster], base: int, branch_ids: list[int],
               vertex_values: list[int]) -> int:
    level = [base, *branch_ids]
    while len(level) > 1:
        next_level: list[int] = []
        for i in range(0, len(level), 2):
            if i + 1 == len(level):
                next_level.append(level[i])
            else:
                next_level.append(_merge(nodes, RAKE, level[i], level[i + 1],
                                         nodes[level[i]].boundary0, vertex_values))
        level = next_level
    return level[0]


def _build(n: int, edge_u: list[int], edge_v: list[int],
           vertex_values: list[int], edge_map: list[tuple[int, int]]) -> tuple[list[_Cluster], int, list[int], list[int]]:
    nodes: list[_Cluster] = []
    vertex_leaf = [_new_vertex(nodes, v, vertex_values) for v in range(n)]
    edge_leaf = [_new_edge(nodes, e, edge_u, edge_v, edge_map)
                 for e in range(n - 1)]
    adjacency = [[False] * n for _ in range(n)]
    edge_cluster = [[-1] * n for _ in range(n)]
    for e, (u, v) in enumerate(zip(edge_u, edge_v)):
        adjacency[u][v] = adjacency[v][u] = True
        edge_cluster[u][v] = edge_cluster[v][u] = edge_leaf[e]
    branches = [[] for _ in range(n)]
    active = [True] * n
    active_count = n

    def neighbors(vertex: int) -> list[int]:
        return [other for other in range(n)
                if active[other] and adjacency[vertex][other]]

    def rake_leaf(x: int, y: int) -> None:
        local = _make_rake(nodes, vertex_leaf[x], branches[x], vertex_values)
        branch = _merge(nodes, BRANCH, edge_cluster[x][y], local, x, vertex_values)
        branches[y].append(branch)

    while active_count > 1:
        if active_count == 2:
            x, y = [v for v in range(n) if active[v]]
            rake_leaf(x, y)
            adjacency[x][y] = adjacency[y][x] = False
            edge_cluster[x][y] = edge_cluster[y][x] = -1
            active[x] = False
            active_count -= 1
            break
        leaves = [v for v in range(n)
                  if active[v] and len(neighbors(v)) == 1]
        for x in leaves:
            rake_leaf(x, neighbors(x)[0])
        for x in leaves:
            y = neighbors(x)[0]
            adjacency[x][y] = adjacency[y][x] = False
            edge_cluster[x][y] = edge_cluster[y][x] = -1
            active[x] = False
            active_count -= 1
        if active_count <= 1:
            break

        chosen = [False] * n
        compress: list[int] = []
        for x in range(n):
            if not active[x] or len(neighbors(x)) != 2:
                continue
            y, z = neighbors(x)
            if not chosen[y] and not chosen[z]:
                chosen[x] = True
                compress.append(x)
        pending: list[tuple[int, int, int, int]] = []
        for x in compress:
            y, z = neighbors(x)
            local = _make_rake(nodes, vertex_leaf[x], branches[x], vertex_values)
            first = _merge(nodes, ATTACH, edge_cluster[y][x], local, x, vertex_values)
            compressed = _merge(nodes, COMPRESS, first, edge_cluster[x][z], x, vertex_values)
            pending.append((x, y, z, compressed))
        for x, y, z, _ in pending:
            adjacency[y][x] = adjacency[x][y] = False
            adjacency[x][z] = adjacency[z][x] = False
            edge_cluster[y][x] = edge_cluster[x][y] = -1
            edge_cluster[x][z] = edge_cluster[z][x] = -1
            active[x] = False
            active_count -= 1
        for _, y, z, compressed in pending:
            adjacency[y][z] = adjacency[z][y] = True
            edge_cluster[y][z] = edge_cluster[z][y] = compressed

    root_vertex = next(v for v in range(n) if active[v])
    root = _make_rake(nodes, vertex_leaf[root_vertex], branches[root_vertex], vertex_values)
    if len(nodes) > MAX_CLUSTER_NODES:
        raise AssertionError("static top-tree node bound exceeded")
    return nodes, root, vertex_leaf, edge_leaf


def _context_for_child(nodes: list[_Cluster], parent_id: int, child_id: int,
                       parent_context: _Context, vertex_values: list[int]) -> _Context:
    parent = nodes[parent_id]
    child = nodes[child_id]
    sibling_id = parent.b if child_id == parent.a else parent.a
    sibling = nodes[sibling_id]
    shared = parent.shared

    overlap = _has(child, shared) and _has(sibling, shared)
    removed = int(overlap)
    total_at_shared = (_sum_at(sibling, shared) -
                       (vertex_values[shared] if overlap else 0)) % MOD
    count_at_shared = sibling.count - removed
    for i in range(sibling.boundary_count):
        boundary = sibling.boundary0 if i == 0 else sibling.boundary1
        pindex = _boundary_index(parent, boundary)
        if pindex < 0:
            continue
        ext_sum = parent_context.sum0 if pindex == 0 else parent_context.sum1
        ext_count = parent_context.count0 if pindex == 0 else parent_context.count1
        total_at_shared = (total_at_shared +
                           _apply(_map_at(sibling, shared, boundary),
                                  ext_sum, ext_count)) % MOD
        count_at_shared += ext_count

    result = _Context()
    for i in range(child.boundary_count):
        boundary = child.boundary0 if i == 0 else child.boundary1
        if boundary == shared:
            out_sum, out_count = total_at_shared, count_at_shared
        else:
            mapping = _map_at(child, boundary, shared)
            out_sum = _apply(mapping, total_at_shared, count_at_shared)
            out_count = count_at_shared
            pindex = _boundary_index(parent, boundary)
            if pindex >= 0:
                ext_sum = parent_context.sum0 if pindex == 0 else parent_context.sum1
                ext_count = parent_context.count0 if pindex == 0 else parent_context.count1
                out_sum = (out_sum + ext_sum) % MOD
                out_count += ext_count
        if i == 0:
            result.sum0, result.count0 = out_sum, out_count
        else:
            result.sum1, result.count1 = out_sum, out_count
    return result


def _query(nodes: list[_Cluster], root: int, vertex_leaf: list[int],
           vertex: int, vertex_values: list[int]) -> int:
    path = [vertex_leaf[vertex]]
    while path[-1] != root:
        parent = nodes[path[-1]].parent
        if parent < 0:
            raise AssertionError("vertex cluster is outside root hierarchy")
        path.append(parent)
    context = _Context()
    for at in range(len(path) - 1, 0, -1):
        parent_id = path[at]
        child_id = path[at - 1]
        context = _context_for_child(nodes, parent_id, child_id,
                                     context, vertex_values)
    leaf = nodes[vertex_leaf[vertex]]
    return (leaf.sum0 + context.sum0) % MOD


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool) -> tuple[
               int, int, list[int], list[int], list[int], list[tuple[int, int]],
               list[tuple[int, int, int, int, int]],
           ] | None:
    if type(input_is_null) is not bool or input_is_null:
        return None
    if not isinstance(values, (list, tuple)):
        return None
    length = len(values) if input_length is None else input_length
    if type(length) is not int or len(values) != length or length < 2 or length > MAX_INPUT:
        return None
    if any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values):
        return None
    n, q = values[0], values[1]
    if not 1 <= n <= MAX_N or not 1 <= q <= MAX_Q:
        return None
    cursor = 2
    vertex_values = list(values[cursor:cursor + n])
    cursor += n
    if len(vertex_values) != n or any(not 0 <= a < MOD for a in vertex_values):
        return None
    edge_u: list[int] = []
    edge_v: list[int] = []
    edge_map: list[tuple[int, int]] = []
    dsu = list(range(n))

    def find(x: int) -> int:
        while dsu[x] != x:
            dsu[x] = dsu[dsu[x]]
            x = dsu[x]
        return x

    for _ in range(n - 1):
        if cursor + 4 > length:
            return None
        u, v, mul, add = values[cursor:cursor + 4]
        cursor += 4
        if not 0 <= u < n or not 0 <= v < n or u == v:
            return None
        if not 1 <= mul < MOD or not 0 <= add < MOD:
            return None
        ru, rv = find(u), find(v)
        if ru == rv:
            return None
        dsu[ru] = rv
        edge_u.append(u)
        edge_v.append(v)
        edge_map.append((mul, add))
    if len({find(v) for v in range(n)}) != 1:
        return None

    operations: list[tuple[int, int, int, int, int]] = []
    for _ in range(q):
        if cursor >= length:
            return None
        opcode = values[cursor]
        cursor += 1
        if opcode == 0:
            if cursor + 3 > length:
                return None
            vertex, value, root = values[cursor:cursor + 3]
            cursor += 3
            if not 0 <= vertex < n or not 0 <= value < MOD or not 0 <= root < n:
                return None
            operations.append((0, vertex, value, 0, root))
        elif opcode == 1:
            if cursor + 4 > length:
                return None
            edge, mul, add, root = values[cursor:cursor + 4]
            cursor += 4
            if not 0 <= edge < n - 1 or not 1 <= mul < MOD or not 0 <= add < MOD or not 0 <= root < n:
                return None
            operations.append((1, edge, mul, add, root))
        else:
            return None
    if cursor != length:
        return None
    return n, q, vertex_values, edge_u, edge_v, edge_map, operations


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return INVALID_RESULT, b""
    n, q, vertex_values, edge_u, edge_v, edge_map, operations = parsed
    if type(output_is_null) is not bool:
        return OUTPUT_ERROR, b""
    capacity = MAX_OUTPUT_BYTES if output_capacity is None else output_capacity
    if type(capacity) is not int or capacity < 0:
        return OUTPUT_ERROR, b""
    required = 8 * q
    if output_is_null or capacity < required:
        return OUTPUT_ERROR, b""

    nodes, root, vertex_leaf, edge_leaf = _build(
        n, edge_u, edge_v, vertex_values, edge_map
    )
    answers: list[int] = []
    for opcode, item, first, second, query_root in operations:
        if opcode == 0:
            vertex_values[item] = first
            node_id = vertex_leaf[item]
            nodes[node_id].sum0 = first
        else:
            edge_map[item] = (first, second)
            node_id = edge_leaf[item]
            nodes[node_id].forward = (first, second)
            nodes[node_id].reverse = (first, second)
        if opcode == 0 or opcode == 1:
            parent = nodes[node_id].parent
            while parent >= 0:
                _recalculate(nodes, parent, vertex_values)
                parent = nodes[parent].parent
        answers.append(_query(nodes, root, vertex_leaf, query_root, vertex_values))
    output = b"".join(value.to_bytes(8, "little", signed=True) for value in answers)
    return len(output), output
