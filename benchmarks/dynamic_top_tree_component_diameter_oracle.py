"""Rake/compress top-tree oracle for a fixed bounded tree with edge updates."""

from __future__ import annotations

from collections.abc import Sequence
from dataclasses import dataclass

MAX_VERTICES = 16
MAX_OPERATIONS = 32
WEIGHT_LIMIT = 1000
MAX_INPUT_LENGTH = 2 + 3 * (MAX_VERTICES - 1) + 3 * MAX_OPERATIONS
MAX_OUTPUT_BYTES = 8 * MAX_OPERATIONS
WORKSPACE_BYTES = 16384
MAX_CLUSTER_NODES = max(1, 5 * MAX_VERTICES - 5)
INVALID_RESULT = -1
OUTPUT_ERROR = -2

EDGE_BASE = 0
EDGE_COMPRESS = 1
RAKE_ZERO = 2
RAKE_MERGE = 3
RAKE_BRANCH = 4


@dataclass
class _Node:
    kind: int
    a: int = -1
    b: int = -1
    c: int = -1
    parent: int = -1
    endpoint0: int = -1
    endpoint1: int = -1
    pivot: int = -1
    edge_id: int = -1
    length: int = 0
    far0: int = 0
    far1: int = 0
    diameter: int = 0
    best1: int = 0
    best2: int = 0


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool) -> tuple[int, list[tuple[int, int, int]], list[tuple[int, int, int]]] | None:
    if type(input_is_null) is not bool or input_is_null:
        return None
    if input_length is not None and (type(input_length) is not int or input_length < 0):
        return None
    if not isinstance(values, (list, tuple)):
        return None
    length = len(values) if input_length is None else input_length
    if len(values) != length or length < 2 or length > MAX_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    n, q = values[0], values[1]
    if not 1 <= n <= MAX_VERTICES or not 0 <= q <= MAX_OPERATIONS:
        return None
    edge_end = 2 + 3 * (n - 1)
    if length != edge_end + 3 * q:
        return None
    edges: list[tuple[int, int, int]] = []
    parent = list(range(n))

    def find(vertex: int) -> int:
        while parent[vertex] != vertex:
            parent[vertex] = parent[parent[vertex]]
            vertex = parent[vertex]
        return vertex

    for edge_id in range(n - 1):
        offset = 2 + 3 * edge_id
        u, v, weight = values[offset:offset + 3]
        if u < 0 or u >= n or v < 0 or v >= n or u == v or not 0 <= weight <= WEIGHT_LIMIT:
            return None
        ru, rv = find(u), find(v)
        if ru == rv:
            return None
        parent[ru] = rv
        edges.append((u, v, weight))
    if len({find(vertex) for vertex in range(n)}) != 1:
        return None

    operations: list[tuple[int, int, int]] = []
    for operation in range(q):
        offset = edge_end + 3 * operation
        opcode, edge_id, value = values[offset:offset + 3]
        if opcode == 0:
            if edge_id < 0 or edge_id >= n - 1 or value < 0 or value > WEIGHT_LIMIT:
                return None
        elif opcode == 1:
            if edge_id != 0 or value != 0:
                return None
        else:
            return None
        operations.append((opcode, edge_id, value))
    return n, edges, operations


def _append_node(nodes: list[_Node], kind: int, weights: list[int], *,
                 a: int = -1, b: int = -1, c: int = -1,
                 endpoint0: int = -1, endpoint1: int = -1,
                 pivot: int = -1, edge_id: int = -1) -> int:
    node_id = len(nodes)
    node = _Node(kind, a, b, c, -1, endpoint0, endpoint1, pivot, edge_id)
    nodes.append(node)
    for child in (a, b, c):
        if child >= 0:
            nodes[child].parent = node_id
    _recalculate(nodes, node_id, weights)
    return node_id


def _far_at(nodes: list[_Node], node_id: int, vertex: int) -> int:
    node = nodes[node_id]
    return node.far0 if node.endpoint0 == vertex else node.far1


def _recalculate(nodes: list[_Node], node_id: int, weights: list[int]) -> None:
    node = nodes[node_id]
    if node.kind == EDGE_BASE:
        weight = weights[node.edge_id]
        node.length = node.far0 = node.far1 = node.diameter = weight
        return
    if node.kind == RAKE_ZERO:
        node.best1 = node.best2 = node.diameter = 0
        return
    if node.kind == RAKE_MERGE:
        left, right = nodes[node.a], nodes[node.b]
        first = second = 0
        for arm in (left.best1, left.best2, right.best1, right.best2):
            if arm >= first:
                first, second = arm, first
            elif arm > second:
                second = arm
        node.best1, node.best2 = first, second
        node.diameter = max(left.diameter, right.diameter, left.best1 + right.best1)
        return
    if node.kind == RAKE_BRANCH:
        edge, local = nodes[node.a], nodes[node.b]
        center_far = _far_at(nodes, node.a, node.endpoint0)
        pivot_far = _far_at(nodes, node.a, node.pivot)
        node.best1 = max(center_far, edge.length + local.best1)
        node.best2 = 0
        node.diameter = max(edge.diameter, local.diameter, pivot_far + local.best1)
        return

    first_edge, second_edge, local = nodes[node.a], nodes[node.b], nodes[node.c]
    y, z, x = node.endpoint0, node.endpoint1, node.pivot
    first_at_y = _far_at(nodes, node.a, y)
    first_at_x = _far_at(nodes, node.a, x)
    second_at_x = _far_at(nodes, node.b, x)
    second_at_z = _far_at(nodes, node.b, z)
    node.length = first_edge.length + second_edge.length
    node.far0 = max(first_at_y, first_edge.length + max(second_at_x, local.best1))
    node.far1 = max(second_at_z, second_edge.length + max(first_at_x, local.best1))
    node.diameter = max(
        first_edge.diameter,
        second_edge.diameter,
        local.diameter,
        first_at_x + second_at_x,
        first_at_x + local.best1,
        second_at_x + local.best1,
    )


def _make_rake_cluster(nodes: list[_Node], weights: list[int],
                       base_id: int, branch_ids: list[int]) -> int:
    level = [base_id, *branch_ids]
    while len(level) > 1:
        next_level: list[int] = []
        at = 0
        while at < len(level):
            if at + 1 == len(level):
                next_level.append(level[at])
            else:
                next_level.append(_append_node(nodes, RAKE_MERGE, weights,
                                               a=level[at], b=level[at + 1]))
            at += 2
        level = next_level
    return level[0]


def _build_hierarchy(n: int, edges: list[tuple[int, int, int]],
                     weights: list[int]) -> tuple[list[_Node], list[int], int]:
    nodes: list[_Node] = []
    base_rake = [_append_node(nodes, RAKE_ZERO, weights) for _ in range(n)]
    adjacency = [[False] * n for _ in range(n)]
    edge_cluster = [[-1] * n for _ in range(n)]
    for edge_id, (u, v, _) in enumerate(edges):
        cluster = _append_node(nodes, EDGE_BASE, weights, endpoint0=u,
                               endpoint1=v, edge_id=edge_id)
        adjacency[u][v] = adjacency[v][u] = True
        edge_cluster[u][v] = edge_cluster[v][u] = cluster

    branches = [[] for _ in range(n)]
    active = [True] * n
    active_count = n

    def neighbors(vertex: int) -> list[int]:
        return [other for other in range(n) if active[other] and adjacency[vertex][other]]

    def rake_into(x: int, y: int) -> None:
        local = _make_rake_cluster(nodes, weights, base_rake[x], branches[x])
        branches[x] = []
        edge = edge_cluster[x][y]
        branch = _append_node(nodes, RAKE_BRANCH, weights, a=edge, b=local,
                              endpoint0=y, pivot=x)
        branches[y].append(branch)

    while active_count > 1:
        if active_count == 2:
            pair = [vertex for vertex in range(n) if active[vertex]]
            x, y = pair[0], pair[1]
            rake_into(x, y)
            adjacency[x][y] = adjacency[y][x] = False
            edge_cluster[x][y] = edge_cluster[y][x] = -1
            active[x] = False
            active_count -= 1
            break

        leaves = [vertex for vertex in range(n)
                  if active[vertex] and len(neighbors(vertex)) == 1]
        for x in leaves:
            y = neighbors(x)[0]
            rake_into(x, y)
        for x in leaves:
            y = neighbors(x)[0]
            adjacency[x][y] = adjacency[y][x] = False
            edge_cluster[x][y] = edge_cluster[y][x] = -1
            active[x] = False
            active_count -= 1
        if active_count <= 1:
            break

        chosen = [False] * n
        compress_vertices: list[int] = []
        for x in range(n):
            if not active[x] or len(neighbors(x)) != 2:
                continue
            adjacent_chosen = any(chosen[y] for y in neighbors(x))
            if not adjacent_chosen:
                chosen[x] = True
                compress_vertices.append(x)

        pending: list[tuple[int, int, int, int]] = []
        for x in compress_vertices:
            y, z = neighbors(x)
            local = _make_rake_cluster(nodes, weights, base_rake[x], branches[x])
            branches[x] = []
            first_edge, second_edge = edge_cluster[y][x], edge_cluster[x][z]
            compressed = _append_node(nodes, EDGE_COMPRESS, weights,
                                      a=first_edge, b=second_edge, c=local,
                                      endpoint0=y, endpoint1=z, pivot=x)
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

    root_vertex = next(vertex for vertex in range(n) if active[vertex])
    root = _make_rake_cluster(nodes, weights, base_rake[root_vertex], branches[root_vertex])
    if len(nodes) > MAX_CLUSTER_NODES:
        raise AssertionError("static top-tree node bound exceeded")
    return nodes, [node_id for node_id, node in enumerate(nodes) if node.kind == EDGE_BASE], root


def _capacity_error(required: int, output_capacity: int | None,
                    output_is_null: bool) -> bool:
    if type(output_is_null) is not bool:
        return True
    if output_capacity is None:
        capacity = MAX_OUTPUT_BYTES
    elif type(output_capacity) is not int or output_capacity < 0:
        return True
    else:
        capacity = output_capacity
    return required > 0 and (output_is_null or capacity < required)


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return INVALID_RESULT, b""
    n, edges, operations = parsed
    query_count = sum(opcode == 1 for opcode, _, _ in operations)
    required = 8 * query_count
    if _capacity_error(required, output_capacity, output_is_null):
        return OUTPUT_ERROR, b""

    weights = [weight for _, _, weight in edges]
    nodes, base_edges, root = _build_hierarchy(n, edges, weights)
    if len(base_edges) != max(0, n - 1):
        return INVALID_RESULT, b""
    edge_base_by_id = {nodes[node_id].edge_id: node_id for node_id in base_edges}
    answers: list[int] = []
    for opcode, edge_id, value in operations:
        if opcode == 0:
            weights[edge_id] = value
            node_id = edge_base_by_id[edge_id]
            _recalculate(nodes, node_id, weights)
            parent = nodes[node_id].parent
            while parent >= 0:
                _recalculate(nodes, parent, weights)
                parent = nodes[parent].parent
        else:
            answers.append(nodes[root].diameter)
    output = b"".join(int(answer).to_bytes(8, "little", signed=True) for answer in answers)
    return len(output), output
