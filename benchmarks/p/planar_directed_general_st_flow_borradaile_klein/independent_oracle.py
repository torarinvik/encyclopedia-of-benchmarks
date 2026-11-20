"""Independent original-network directed-cut oracle; never run here."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 6
MAX_M = 10
MAX_VALID_INPUT_LENGTH = 60
MAX_PARSEABLE_INPUT_LENGTH = 61
MAX_OUTPUT_BYTES = 8
MAX_WORKSPACE_BYTES = 8192
WORKSPACE_BYTES = MAX_WORKSPACE_BYTES


def _read_frame(words):
    if not 4 <= len(words) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(word) is not int or not -(1 << 63) <= word < (1 << 63) for word in words):
        return None
    n, m, s, t = words[:4]
    if not (2 <= n <= MAX_N and 1 <= m <= MAX_M and 0 <= s < n and 0 <= t < n and s != t):
        return None
    if len(words) < 4 + 3 * m:
        return None
    position = 4
    arcs = []
    endpoint_pairs = set()
    for edge_id in range(m):
        tail, head, weight = words[position : position + 3]
        position += 3
        undirected_pair = tuple(sorted((tail, head)))
        if not (0 <= tail < n and 0 <= head < n and tail != head):
            return None
        if not 1 <= weight <= 5 or undirected_pair in endpoint_pairs:
            return None
        endpoint_pairs.add(undirected_pair)
        arcs.append((tail, head, weight))

    stars = [[] for _ in range(n)]
    occurrences = [[0, 0] for _ in arcs]
    for vertex in range(n):
        if position == len(words):
            return None
        degree = words[position]
        position += 1
        if not 0 <= degree < n or position + degree > len(words):
            return None
        star = list(words[position : position + degree])
        position += degree
        if len(set(star)) != degree:
            return None
        for edge_id in star:
            if not 0 <= edge_id < m:
                return None
            a, b, _ = arcs[edge_id]
            if vertex == a:
                occurrences[edge_id][0] += 1
            elif vertex == b:
                occurrences[edge_id][1] += 1
            else:
                return None
        stars[vertex] = star
    if position != len(words) or any(counts != [1, 1] for counts in occurrences):
        return None

    # Independent embedding validation from Euler's formula and face cycles.
    neighbors = [[] for _ in range(n)]
    for edge_id, (a, b, _) in enumerate(arcs):
        neighbors[a].append(b)
        neighbors[b].append(a)
    reached = [False] * n
    reached[s] = True
    todo = [s]
    while todo:
        x = todo.pop()
        for y in neighbors[x]:
            if not reached[y]:
                reached[y] = True
                todo.append(y)
    if not all(reached):
        return None

    slots = [[-1] * m for _ in range(n)]
    for vertex, star in enumerate(stars):
        for i, edge_id in enumerate(star):
            slots[vertex][edge_id] = i

    def endpoint(dart):
        a, b, _ = arcs[dart >> 1]
        return (a, b) if dart & 1 == 0 else (b, a)

    def successor(dart):
        _, vertex = endpoint(dart)
        star = stars[vertex]
        reverse_edge = dart >> 1
        place = slots[vertex][reverse_edge]
        if place < 0 or not star:
            return -1
        edge_id = star[(place - 1) % len(star)]
        a, b, _ = arcs[edge_id]
        return 2 * edge_id + int(vertex == b)

    face = [-1] * (2 * m)
    found_faces = 0
    for first in range(2 * m):
        if face[first] != -1:
            continue
        current = first
        while face[current] == -1:
            face[current] = found_faces
            current = successor(current)
            if current < 0:
                return None
        if current != first:
            return None
        found_faces += 1
    if found_faces != m - n + 2:
        return None
    return n, m, s, t, arcs


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if input_length is not None and (
        type(input_length) is not int or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
    ):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    decoded = _read_frame(values)
    if decoded is None:
        return -1, b""
    n, _, source, sink, arcs = decoded

    # For each source-containing vertex subset, sum original directed arcs
    # leaving it. The minimum is the max-flow value by the cut theorem.
    optimum = None
    for side in range(1 << n):
        if not ((side >> source) & 1) or ((side >> sink) & 1):
            continue
        cut_capacity = sum(
            weight for tail, head, weight in arcs
            if ((side >> tail) & 1) and not ((side >> head) & 1)
        )
        optimum = cut_capacity if optimum is None else min(optimum, cut_capacity)
    assert optimum is not None
    payload = struct.pack("<q", optimum)
    if output_is_null or (capacity is not None and capacity < len(payload)):
        return -2, b""
    return len(payload), payload
