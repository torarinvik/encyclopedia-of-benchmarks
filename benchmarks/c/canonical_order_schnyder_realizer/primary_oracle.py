"""Primary bounded reference for the canonical-order Schnyder realizer."""

from __future__ import annotations

import struct
from collections.abc import Sequence

from ..canonical_order_maximal_plane_triangulation import primary_oracle as canonical

MAX_N = 8
MAX_VALID_INPUT_LENGTH = 8 * MAX_N - 8
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (1 + 4 * (MAX_N - 3))
WORKSPACE_BYTES = 4096


def _realizer(values: Sequence[int]) -> tuple[int, list[tuple[int, int, int, int]]] | None:
    if not 4 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    n_raw = values[0]
    if not 3 <= n_raw <= MAX_N:
        return None
    n = n_raw
    if len(values) < n:
        return None
    graph_values = values[:-n]
    parsed = canonical._decode(graph_values)
    if parsed is None:
        return None
    n2, u, v, w, rotations, adjacent = parsed
    if n2 != n:
        return None
    order = list(values[-n:])
    if (len(set(order)) != n or set(order) != set(range(n))
            or order[0] != u or order[1] != v or order[-1] != w):
        return None

    active = [True] * n
    if n == 3:
        path = canonical._boundary(rotations, adjacent, active, u, v)
        if path is None or path != [u, order[2], v]:
            return None
    else:
        active[w] = False
        path = canonical._boundary(rotations, adjacent, active, u, v)
        if path is None:
            return None
        root_neighbors = [node for node in path if adjacent[w][node]]
        if len(root_neighbors) < 2:
            return None
        all_root_neighbors = {node for node in range(n) if active[node] and adjacent[w][node]}
        if all_root_neighbors != set(root_neighbors):
            return None
        root_positions = [path.index(node) for node in root_neighbors]
        if max(root_positions) - min(root_positions) + 1 != len(root_neighbors):
            return None
        for candidate in reversed(order[3:-1]):
            if candidate not in canonical._eligible(path, adjacent):
                return None
            active[candidate] = False
            path = canonical._boundary(rotations, adjacent, active, u, v)
            if path is None:
                return None
        if path != [u, order[2], v]:
            return None

    positions = [0] * n
    for rank, vertex in enumerate(order):
        positions[vertex] = rank
    records: list[tuple[int, int, int, int]] = []
    for rank in range(2, n - 1):
        vertex = order[rank]
        if rank == 2:
            left_parent, right_parent = u, v
        else:
            prefix_active = [False] * n
            for earlier in order[:rank]:
                prefix_active[earlier] = True
            boundary = canonical._boundary(rotations, adjacent, prefix_active, u, v)
            if boundary is None:
                return None
            predecessors = [node for node in boundary if adjacent[vertex][node]]
            if len(predecessors) < 2:
                return None
            earlier_neighbors = {node for node in range(n) if prefix_active[node] and adjacent[vertex][node]}
            if earlier_neighbors != set(predecessors):
                return None
            boundary_positions = [boundary.index(node) for node in predecessors]
            if max(boundary_positions) - min(boundary_positions) + 1 != len(predecessors):
                return None
            left_parent, right_parent = predecessors[0], predecessors[-1]
        later = [node for node in range(n) if positions[node] > rank and adjacent[vertex][node]]
        if not later:
            return None
        successor_parent = max(later, key=positions.__getitem__)
        records.append((vertex, left_parent, right_parent, successor_parent))

    if not _parent_conditions(n, u, v, w, rotations, adjacent, records):
        return None
    return n, records


def _parent_conditions(n: int, u: int, v: int, w: int,
                       rotations: list[list[int]],
                       adjacent: list[list[bool]],
                       records: list[tuple[int, int, int, int]]) -> bool:
    if len(records) != n - 3:
        return False
    roots = (u, v, w)
    parents = [{record[0]: record[color + 1] for record in records} for color in range(3)]
    used: set[tuple[int, int]] = set()
    colors = [[-1] * n for _ in range(n)]
    owners = [[-1] * n for _ in range(n)]
    for vertex, *triple in records:
        if len(set(triple)) != 3:
            return False
        for color, parent in enumerate(triple):
            if not 0 <= parent < n or not adjacent[vertex][parent]:
                return False
            edge = (min(vertex, parent), max(vertex, parent))
            if edge in used or set(edge) == {u, v} or set(edge) == {v, w} or set(edge) == {u, w}:
                return False
            used.add(edge)
            colors[vertex][parent] = colors[parent][vertex] = color
            owners[vertex][parent] = owners[parent][vertex] = vertex
            current = vertex
            seen: set[int] = set()
            while current != roots[color]:
                if current in seen or current not in parents[color]:
                    return False
                seen.add(current)
                current = parents[color][current]
    internal_edges = {
        (a, b) for a in range(n) for b in range(a + 1, n)
        if adjacent[a][b] and {a, b} not in ({u, v}, {v, w}, {u, w})
    }
    if used != internal_edges:
        return False

    # Chapter 650's clockwise local rule is out T1, in T2, out T3, in T1,
    # out T2, in T3. Incoming sectors may have no edges.
    for vertex in range(n):
        if vertex in roots:
            continue
        outgoing_position = [-1] * 3
        tokens: list[int] = []
        # The row advances with the face-walk successor. Because the selected
        # outer cycle u,v,w is counterclockwise, the local clockwise view used
        # by Chapter 650 is the reverse cyclic traversal of that stored row.
        for position, neighbor in enumerate(reversed(rotations[vertex])):
            color = colors[vertex][neighbor]
            if color < 0:
                return False
            if owners[vertex][neighbor] == vertex:
                if outgoing_position[color] >= 0:
                    return False
                outgoing_position[color] = position
                tokens.append(color)
            else:
                tokens.append(3 + color)
        if any(position < 0 for position in outgoing_position):
            return False
        degree = len(tokens)
        phases = ((0, 2, 4), (2, 1, 3), (1, 0, 5))
        for start_color, next_color, incoming_token in phases:
            position = (outgoing_position[start_color] + 1) % degree
            next_position = outgoing_position[next_color]
            while position != next_position:
                if tokens[position] != incoming_token:
                    return False
                position = (position + 1) % degree
    return True


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if input_length is not None and (
            type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    result = _realizer(values)
    if result is None:
        return -1, b""
    n, records = result
    words = (n, *(word for record in records for word in record))
    payload = b"".join(struct.pack("<q", word) for word in words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
