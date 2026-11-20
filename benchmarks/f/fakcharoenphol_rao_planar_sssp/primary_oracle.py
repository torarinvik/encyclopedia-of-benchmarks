"""Bounded clean-room FR dense-distance/online-Monge SSSP reference.

This is an executable specification for the bounded profile, not a port of
the paper's asymptotically faster interval/heap data structure.  Its bounded
online Monge blocks keep the same activate, query-minimum, and settle state
machine, with direct scans for each operation.
"""
from __future__ import annotations

from collections.abc import Sequence
from dataclasses import dataclass

MAX_N = 12
MAX_M = 60
MAX_PIECES = 2 * MAX_M - 1
MAX_BOUNDARY = 12
MAX_BASE_ARCS = 3
MAX_ABS_WEIGHT = 100
MAX_INPUT_LENGTH = 4 + 3 * MAX_M + MAX_PIECES * (4 + MAX_BOUNDARY)
MAX_VALID_INPUT_LENGTH = MAX_INPUT_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH
MAX_OUTPUT_BYTES = 8 * MAX_N
MAX_WORKSPACE_BYTES = 262_144
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2
INF = 1 << 60


@dataclass(frozen=True)
class Piece:
    left: int
    right: int
    edge_mask: int
    vertex_mask: int
    boundary: tuple[int, ...]


@dataclass(frozen=True)
class Parsed:
    n: int
    m: int
    source: int
    edges: tuple[tuple[int, int, int], ...]
    pieces: tuple[Piece, ...]


@dataclass(frozen=True)
class Block:
    rows: tuple[int, ...]
    columns: tuple[int, ...]
    weights: tuple[tuple[int, ...], ...]


def _is_i64(value: object) -> bool:
    return type(value) is int and -(1 << 63) <= value < (1 << 63)


def parse_input(values: Sequence[int] | None, input_is_null: bool = False,
                input_length: int | None = None) -> Parsed | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 4 <= len(values) <= MAX_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(not _is_i64(value) for value in values)):
        return None

    n, m, source, piece_count = values[:4]
    if not 2 <= n <= MAX_N or not 1 <= m <= MAX_M:
        return None
    if not 0 <= source < n:
        return None
    if not 1 <= piece_count <= MAX_PIECES or piece_count % 2 != 1:
        return None

    offset = 4
    edges: list[tuple[int, int, int]] = []
    seen_arcs: set[tuple[int, int]] = set()
    underlying_pairs: set[tuple[int, int]] = set()
    adjacency = [[] for _ in range(n)]
    for _ in range(m):
        if offset + 3 > len(values):
            return None
        u, v, weight = values[offset:offset + 3]
        offset += 3
        if (not 0 <= u < n or not 0 <= v < n or u == v
                or abs(weight) > MAX_ABS_WEIGHT):
            return None
        arc = (u, v)
        if arc in seen_arcs:
            return None
        seen_arcs.add(arc)
        underlying_pairs.add((min(u, v), max(u, v)))
        edges.append((u, v, weight))
        adjacency[u].append(v)
        adjacency[v].append(u)
    simple_edge_bound = 1 if n == 2 else 3 * n - 6
    if len(underlying_pairs) > simple_edge_bound or m > 2 * simple_edge_bound:
        return None

    reached = {0}
    stack = [0]
    while stack:
        u = stack.pop()
        for v in adjacency[u]:
            if v not in reached:
                reached.add(v)
                stack.append(v)
    if len(reached) != n:
        return None

    pieces: list[Piece] = []
    parent_count = [0] * piece_count
    leaf_union = 0
    leaf_count = 0
    full_edge_mask = (1 << m) - 1
    for index in range(piece_count):
        if offset + 4 > len(values):
            return None
        left, right, supplied_mask, boundary_count = values[offset:offset + 4]
        offset += 4
        if not 1 <= boundary_count <= min(n, MAX_BOUNDARY):
            return None
        if offset + boundary_count > len(values):
            return None
        boundary = tuple(values[offset:offset + boundary_count])
        offset += boundary_count
        if (any(not 0 <= vertex < n for vertex in boundary)
                or len(set(boundary)) != boundary_count):
            return None

        if left == -1 and right == -1:
            edge_mask = supplied_mask
            if (edge_mask <= 0 or edge_mask & ~full_edge_mask
                    or edge_mask.bit_count() > MAX_BASE_ARCS
                    or leaf_union & edge_mask):
                return None
            leaf_union |= edge_mask
            leaf_count += 1
            vertex_mask = 0
            base_vertices: set[int] = set()
            for edge_id, (u, v, _weight) in enumerate(edges):
                if edge_mask & (1 << edge_id):
                    vertex_mask |= (1 << u) | (1 << v)
                    base_vertices.add(u)
                    base_vertices.add(v)
            if not _connected_vertices(base_vertices, edge_mask, edges):
                return None
        else:
            if (left < 0 or right < 0 or left >= index or right >= index
                    or left == right or supplied_mask != -1):
                return None
            if parent_count[left] or parent_count[right]:
                return None
            parent_count[left] += 1
            parent_count[right] += 1
            left_piece, right_piece = pieces[left], pieces[right]
            if left_piece.edge_mask & right_piece.edge_mask:
                return None
            edge_mask = left_piece.edge_mask | right_piece.edge_mask
            vertex_mask = left_piece.vertex_mask | right_piece.vertex_mask
            parent_vertices = vertex_mask.bit_count()
            max_child_vertices = (2 * parent_vertices + 2) // 3
            if (left_piece.vertex_mask.bit_count() > max_child_vertices
                    or right_piece.vertex_mask.bit_count() > max_child_vertices):
                return None
            if not (left_piece.vertex_mask & right_piece.vertex_mask):
                return None

        vertices = {vertex for vertex in range(n) if vertex_mask & (1 << vertex)}
        expected_boundary: set[int] = set()
        for vertex in vertices:
            if vertex == source:
                expected_boundary.add(vertex)
                continue
            for edge_id, (u, v, _weight) in enumerate(edges):
                if not (edge_mask & (1 << edge_id)) and (u == vertex or v == vertex):
                    expected_boundary.add(vertex)
                    break
        if set(boundary) != expected_boundary:
            return None
        if index == piece_count - 1:
            if edge_mask != full_edge_mask or vertex_mask != (1 << n) - 1:
                return None
        pieces.append(Piece(left, right, edge_mask, vertex_mask, boundary))

    if (offset != len(values) or piece_count != 2 * leaf_count - 1
            or leaf_union != full_edge_mask or parent_count[-1] != 0
            or any(parent_count[i] != 1 for i in range(piece_count - 1))):
        return None
    if pieces[-1].boundary != (source,):
        return None
    return Parsed(n, m, source, tuple(edges), tuple(pieces))


def _connected_vertices(vertices: set[int], edge_mask: int,
                        edges: Sequence[tuple[int, int, int]]) -> bool:
    if not vertices:
        return False
    start = min(vertices)
    reached = {start}
    stack = [start]
    while stack:
        u = stack.pop()
        for edge_id, (a, b, _weight) in enumerate(edges):
            if edge_mask & (1 << edge_id) and (a == u or b == u):
                v = b if a == u else a
                if v not in reached:
                    reached.add(v)
                    stack.append(v)
    return reached == vertices


def _piece_arcs(parsed: Parsed, edge_mask: int) -> list[tuple[int, int, int]]:
    arcs: list[tuple[int, int, int]] = []
    for edge_id, (u, v, weight) in enumerate(parsed.edges):
        if edge_mask & (1 << edge_id):
            arcs.append((u, v, weight))
    return arcs


def _bellman_ford_all(nodes: Sequence[int],
                      arcs: Sequence[tuple[int, int, int]]) -> dict[int, int] | None:
    labels = {vertex: 0 for vertex in nodes}
    for _ in range(max(0, len(nodes) - 1)):
        changed = False
        for u, v, weight in arcs:
            candidate = labels[u] + weight
            if candidate < labels[v]:
                labels[v] = candidate
                changed = True
        if not changed:
            break
    for u, v, weight in arcs:
        if labels[u] + weight < labels[v]:
            return None
    return labels


def _bellman_ford_seeded(n: int, arcs: Sequence[tuple[int, int, int]],
                         seeds: dict[int, int]) -> list[int] | None:
    labels = [INF] * n
    for vertex, value in seeds.items():
        labels[vertex] = min(labels[vertex], value)
    for _ in range(max(0, n - 1)):
        changed = False
        for u, v, weight in arcs:
            if labels[u] != INF and labels[u] + weight < labels[v]:
                labels[v] = labels[u] + weight
                changed = True
        if not changed:
            break
    for u, v, weight in arcs:
        if labels[u] != INF and labels[u] + weight < labels[v]:
            return None
    return labels


def _piece_has_negative_cycle(nodes: Sequence[int],
                              arcs: Sequence[tuple[int, int, int]]) -> bool:
    return _bellman_ford_all(nodes, arcs) is None


def _make_blocks(boundary: Sequence[int],
                 distances: dict[tuple[int, int], int],
                 potential: dict[int, int]) -> list[Block]:
    blocks: list[Block] = []

    def add(rows: Sequence[int], columns: Sequence[int]) -> None:
        weights = tuple(tuple(
            INF if distances[(u, v)] == INF
            else distances[(u, v)] + potential[u] - potential[v]
            for v in columns) for u in rows)
        blocks.append(Block(tuple(rows), tuple(columns), weights))

    def divide(lo: int, hi: int) -> None:
        if hi - lo <= 1:
            return
        middle = (lo + hi) // 2
        left = boundary[lo:middle]
        right = boundary[middle:hi]
        add(left, right)
        add(right, left)
        divide(lo, middle)
        divide(middle, hi)

    divide(0, len(boundary))
    return blocks


def _is_monge_blocks(boundary: Sequence[int],
                     distances: dict[tuple[int, int], int]) -> bool:
    def check(rows: Sequence[int], columns: Sequence[int]) -> bool:
        for i in range(len(rows)):
            for i2 in range(i + 1, len(rows)):
                for j in range(len(columns)):
                    for j2 in range(j + 1, len(columns)):
                        a = distances[(rows[i], columns[j])]
                        b = distances[(rows[i2], columns[j2])]
                        c = distances[(rows[i], columns[j2])]
                        d = distances[(rows[i2], columns[j])]
                        lhs = INF if a == INF or b == INF else a + b
                        rhs = INF if c == INF or d == INF else c + d
                        if lhs > rhs:
                            return False
        return True

    def divide(lo: int, hi: int) -> bool:
        if hi - lo <= 1:
            return True
        middle = (lo + hi) // 2
        left, right = boundary[lo:middle], boundary[middle:hi]
        return (check(left, right) and check(right, left)
                and divide(lo, middle) and divide(middle, hi))

    return divide(0, len(boundary))


def _online_monge_dijkstra(nodes: Sequence[int], blocks: Sequence[Block],
                            initial: dict[int, int]) -> dict[int, int]:
    """FR activate/query/settle state machine with bounded direct scans."""
    settled: set[int] = set()
    labels = {vertex: INF for vertex in nodes}
    row_occurrences: dict[int, list[tuple[int, int]]] = {v: [] for v in nodes}
    column_occurrences: dict[int, list[tuple[int, int]]] = {v: [] for v in nodes}
    best_values: list[list[int]] = []
    best_rows: list[list[int]] = []

    for block_index, block in enumerate(blocks):
        best_values.append([INF] * len(block.columns))
        best_rows.append([INF] * len(block.columns))
        for row_index, vertex in enumerate(block.rows):
            row_occurrences[vertex].append((block_index, row_index))
        for column_index, vertex in enumerate(block.columns):
            column_occurrences[vertex].append((block_index, column_index))

    def activate(vertex: int, value: int) -> None:
        for block_index, row_index in row_occurrences[vertex]:
            block = blocks[block_index]
            for column_index, target in enumerate(block.columns):
                if target in settled:
                    continue
                weight = block.weights[row_index][column_index]
                if weight == INF:
                    continue
                candidate = value + weight
                old = (best_values[block_index][column_index],
                       best_rows[block_index][column_index])
                if (candidate, vertex) < old:
                    best_values[block_index][column_index] = candidate
                    best_rows[block_index][column_index] = vertex

    def settle(vertex: int) -> None:
        settled.add(vertex)
        for block_index, column_index in column_occurrences[vertex]:
            best_values[block_index][column_index] = INF
            best_rows[block_index][column_index] = INF

    for vertex, value in initial.items():
        if vertex not in labels:
            continue
        labels[vertex] = min(labels[vertex], value)
    # Seed labels are tentative sources for this bounded multi-source run. They
    # must participate in the same global extraction order as DDG candidates:
    # during top-down expansion, one supplied boundary label can be improved
    # through another supplied boundary vertex.
    for vertex in sorted(initial):
        if vertex in labels and labels[vertex] != INF:
            activate(vertex, labels[vertex])

    while True:
        best: tuple[int, int, int] | None = None
        for vertex in nodes:
            value = labels[vertex]
            if value != INF and vertex not in settled:
                candidate = (value, vertex, -1)
                if best is None or candidate < best:
                    best = candidate
        for block_index, block in enumerate(blocks):
            for column_index, target in enumerate(block.columns):
                value = best_values[block_index][column_index]
                row = best_rows[block_index][column_index]
                if value == INF or target in settled:
                    continue
                candidate = (value, target, row)
                if best is None or candidate < best:
                    best = candidate
        if best is None:
            break
        value, vertex, _row = best
        labels[vertex] = min(labels[vertex], value)
        settle(vertex)
        activate(vertex, labels[vertex])
    return labels


def _compute_primary(parsed: Parsed) -> list[int] | None:
    # A negative cycle may be entirely internal to one piece and absent from
    # every boundary DDG. Validate the original graph before building the
    # hierarchy summaries so the input policy is checked globally.
    if _bellman_ford_all(tuple(range(parsed.n)), parsed.edges) is None:
        return None

    pieces = parsed.pieces
    distance_tables: list[dict[tuple[int, int], int]] = []
    potentials: list[dict[int, int] | None] = [None] * len(pieces)
    profiles: list[tuple[tuple[int, ...], list[Block]] | None] = [None] * len(pieces)

    for index, piece in enumerate(pieces):
        if piece.left == -1:
            arcs = _piece_arcs(parsed, piece.edge_mask)
            nodes = [vertex for vertex in range(parsed.n)
                     if piece.vertex_mask & (1 << vertex)]
            if _piece_has_negative_cycle(nodes, arcs):
                return None
            matrix: dict[tuple[int, int], int] = {}
            for source in piece.boundary:
                labels = _bellman_ford_seeded(parsed.n, arcs, {source: 0})
                if labels is None:
                    return None
                for target in piece.boundary:
                    matrix[(source, target)] = labels[target]
            distance_tables.append(matrix)
            continue

        children = (piece.left, piece.right)
        child_boundaries = [pieces[child].boundary for child in children]
        nodes = tuple(sorted(set(child_boundaries[0]) | set(child_boundaries[1])))
        if not set(piece.boundary).issubset(nodes):
            return None
        union_arcs: list[tuple[int, int, int]] = []
        for child in children:
            child_boundary = pieces[child].boundary
            child_distances = distance_tables[child]
            for u in child_boundary:
                for v in child_boundary:
                    if u != v:
                        weight = child_distances[(u, v)]
                        if weight == INF:
                            continue
                        union_arcs.append((u, v, weight))
        potential = _bellman_ford_all(nodes, union_arcs)
        if potential is None:
            return None
        for u, v, weight in union_arcs:
            if weight + potential[u] - potential[v] < 0:
                return None
        blocks: list[Block] = []
        for child in children:
            child_boundary = pieces[child].boundary
            child_distances = distance_tables[child]
            if not _is_monge_blocks(child_boundary, child_distances):
                return None
            blocks.extend(_make_blocks(child_boundary, child_distances, potential))
        profiles[index] = (nodes, blocks)
        potentials[index] = potential

        matrix = {}
        for source in piece.boundary:
            reduced = _online_monge_dijkstra(nodes, blocks, {source: 0})
            for target in piece.boundary:
                if reduced[target] == INF:
                    matrix[(source, target)] = INF
                else:
                    matrix[(source, target)] = reduced[target] - potential[source] + potential[target]
        distance_tables.append(matrix)

    output = [INF] * parsed.n

    def expand(index: int, known: dict[int, int]) -> None:
        piece = pieces[index]
        if piece.left == -1:
            arcs = _piece_arcs(parsed, piece.edge_mask)
            labels = _bellman_ford_seeded(parsed.n, arcs, known)
            if labels is None:
                return
            for vertex in range(parsed.n):
                if piece.vertex_mask & (1 << vertex):
                    output[vertex] = min(output[vertex], labels[vertex])
            return

        profile = profiles[index]
        potential = potentials[index]
        if profile is None or potential is None:
            return
        nodes, blocks = profile
        reduced_seeds = {vertex: value - potential[vertex]
                          for vertex, value in known.items() if vertex in potential}
        reduced = _online_monge_dijkstra(nodes, blocks, reduced_seeds)
        raw = {vertex: value + potential[vertex]
               for vertex, value in reduced.items() if value != INF}
        expand(piece.left, {vertex: raw[vertex]
                            for vertex in pieces[piece.left].boundary if vertex in raw})
        expand(piece.right, {vertex: raw[vertex]
                             for vertex in pieces[piece.right].boundary if vertex in raw})

    expand(len(pieces) - 1, {parsed.source: 0})
    return [((1 << 63) - 1 if value == INF else value) for value in output]


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = parse_input(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    distances = _compute_primary(parsed)
    if distances is None:
        return INVALID_RESULT, b""
    payload = b"".join(value.to_bytes(8, "little", signed=True)
                        for value in distances)
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0 or output_is_null
            or effective_capacity < len(payload)):
        return OUTPUT_ERROR_RESULT, b""
    return len(payload), payload
