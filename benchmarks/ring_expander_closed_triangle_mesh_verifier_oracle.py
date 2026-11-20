"""Independent pairwise-neighbor oracle for the bounded Ring-Expander profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT_LENGTH = 64
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH
MAX_OUTPUT_BYTES = 504
WORKSPACE_BYTES = 8192
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 15 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(x) is not int or not I64_MIN <= x <= I64_MAX for x in values)):
        return None
    n, t, seed = values[0], values[1], values[2]
    if not 4 <= n <= 12 or not 4 <= t <= 20 or len(values) != 3 + 3 * t:
        return None
    if not 0 <= seed < 3 * t:
        return None
    faces = [tuple(values[3 + 3 * k:6 + 3 * k]) for k in range(t)]
    for face in faces:
        if any(v < 0 or v >= n for v in face) or len(set(face)) != 3:
            return None
    canonical = [tuple(sorted(face)) for face in faces]
    if len(set(canonical)) != t:
        return None
    return n, t, seed, faces


def _run(n: int, t: int, seed: int, faces: list[tuple[int, int, int]]):
    # Build only the vertex-link input here. Opposite corners are found later by
    # scanning all face edges, independently of the primary incidence buckets.
    links: list[list[tuple[int, int]]] = [[] for _ in range(n)]
    for face in faces:
        a, b, c = face
        links[a].append((b, c))
        links[b].append((c, a))
        links[c].append((a, b))
    if any(not links[v] for v in range(n)):
        return None

    def edge_endpoints(corner: int) -> tuple[int, int]:
        ti, j = divmod(corner, 3)
        return faces[ti][(j + 1) % 3], faces[ti][(j + 2) % 3]

    def opposite(corner: int) -> int:
        x, y = edge_endpoints(corner)
        incidences: list[tuple[int, int, int]] = []
        for ti, face in enumerate(faces):
            for local in range(3):
                a, b = face[(local + 1) % 3], face[(local + 2) % 3]
                if (a == x and b == y) or (a == y and b == x):
                    incidences.append((3 * ti + local, a, b))
        if len(incidences) != 2:
            return -1
        other = next((entry for entry in incidences if entry[0] != corner), None)
        if other is None or (x, y) != (other[2], other[1]):
            return -1
        return other[0]

    opposite_table = [opposite(c) for c in range(3 * t)]
    if any(x < 0 for x in opposite_table):
        return None

    # A vertex link is represented as the graph of the two other vertices in
    # each incident face. It must be one connected cycle, not several fans.
    for vertex in range(n):
        adjacency: dict[int, set[int]] = {}
        for first, second in links[vertex]:
            adjacency.setdefault(first, set()).add(second)
            adjacency.setdefault(second, set()).add(first)
        if not adjacency or any(len(row) != 2 for row in adjacency.values()):
            return None
        reached = {next(iter(adjacency))}
        pending = list(reached)
        while pending:
            item = pending.pop()
            for neighbor in adjacency[item]:
                if neighbor not in reached:
                    reached.add(neighbor)
                    pending.append(neighbor)
        if len(reached) != len(adjacency):
            return None

    # Triangle connectivity is checked by walking the direct pairwise opposite
    # relation instead of the primary oracle's prebuilt neighbor lists.
    reached_triangles = {0}
    pending = [0]
    while pending:
        ti = pending.pop()
        for local in range(3):
            other = opposite_table[3 * ti + local] // 3
            if other not in reached_triangles:
                reached_triangles.add(other)
                pending.append(other)
    if len(reached_triangles) != t:
        return None

    seen_vertices = 0
    seen_triangles = 0
    trace: list[int] = []
    visited_corners: set[int] = set()
    c = seed
    ti, j = divmod(c, 3)
    seen_vertices |= 1 << faces[ti][(j + 1) % 3]
    seen_vertices |= 1 << faces[ti][(j + 2) % 3]
    stop = opposite_table[seed]
    while c != stop:
        if c in visited_corners or len(trace) >= 3 * t:
            return None
        visited_corners.add(c)
        trace.append(c)
        ti, j = divmod(c, 3)
        vertex = faces[ti][j]
        if not (seen_vertices >> vertex) & 1:
            seen_vertices |= 1 << vertex
            seen_triangles |= 1 << ti
        elif not (seen_triangles >> ti) & 1:
            c = opposite_table[c]
        ti, j = divmod(c, 3)
        previous_corner = 3 * ti + (j + 2) % 3
        c = opposite_table[previous_corner]
    words = [len(trace), *trace, seen_vertices, seen_triangles]
    return struct.pack("<" + "q" * len(words), *words)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    payload = _run(*parsed)
    if payload is None:
        return -1, b""
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
