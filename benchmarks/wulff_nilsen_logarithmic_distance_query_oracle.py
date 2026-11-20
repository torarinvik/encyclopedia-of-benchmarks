"""Primary bounded reference for Wulff--Nilsen's logarithmic-query profile."""

from __future__ import annotations

import struct

K = 16
MAX_N = 8
MAX_M = MAX_N * (MAX_N - 1) // 2
MAX_Q = 32
MAX_WEIGHT = 1000
MAX_VALID_INPUT = 2 + 15 + 3 * MAX_M + 1 + 2 * MAX_Q
MAX_PARSEABLE_INPUT = MAX_VALID_INPUT + 1
MAX_OUTPUT_BYTES = 8 * (1 + 2 * MAX_Q)
MAX_WORKSPACE_BYTES = 16384
INVALID_RESULT = -1
OUTPUT_ERROR = -2
INF = 1 << 60
BASE_SPAN = 4  # log2(K)


def _parse(values: tuple[int, ...], length: int, input_is_null: bool):
    if input_is_null or length != len(values) or not 2 + 15 + 1 <= length <= MAX_PARSEABLE_INPUT:
        return None
    n, m = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= m <= MAX_M:
        return None
    masks = values[2:17]
    if len(masks) != 15:
        return None
    limit = 1 << n
    for mask in masks:
        if mask <= 0 or mask >= limit:
            return None
    for i in range(14):
        if masks[i + 1] & ~masks[i]:
            return None

    q_at = 17 + 3 * m
    if q_at >= length:
        return None
    q = values[q_at]
    if not 0 <= q <= MAX_Q or length != q_at + 1 + 2 * q:
        return None

    edges = []
    previous = None
    for e in range(m):
        u, v, weight = values[17 + 3 * e:20 + 3 * e]
        if not (0 <= u < v < n and 1 <= weight <= MAX_WEIGHT):
            return None
        pair = (u, v)
        if previous is not None and pair <= previous:
            return None
        previous = pair
        edges.append((u, v, weight))

    queries = []
    for i in range(q):
        u, v = values[q_at + 1 + 2 * i:q_at + 3 + 2 * i]
        if not (0 <= u < n and 0 <= v < n):
            return None
        queries.append((u, v))
    return n, masks, edges, queries


def _distances(n: int, edges: list[tuple[int, int, int]]) -> list[list[int]]:
    distance = [[0 if i == j else INF for j in range(n)] for i in range(n)]
    for u, v, weight in edges:
        distance[u][v] = distance[v][u] = weight
    for k in range(n):
        for i in range(n):
            for j in range(n):
                candidate = distance[i][k] + distance[k][j]
                if candidate < distance[i][j]:
                    distance[i][j] = candidate
    return distance


def _prepare(n: int, masks: tuple[int, ...], distance: list[list[int]]):
    sample_masks = (0, *masks, 0)  # A0 is handled as V; A16 is empty.
    nearest = [[0] * n for _ in range(K)]
    for vertex in range(n):
        nearest[0][vertex] = vertex
    for level in range(1, K):
        candidates = [v for v in range(n) if (masks[level - 1] >> v) & 1]
        for vertex in range(n):
            nearest[level][vertex] = min(candidates, key=lambda v: (distance[vertex][v], v))

    bunch = [[False] * n for _ in range(n)]
    for center in range(n):
        for level in range(K):
            current = ((1 << n) - 1) if level == 0 else sample_masks[level]
            following = sample_masks[level + 1]
            next_distance = min((distance[center][v] for v in range(n) if (following >> v) & 1), default=INF)
            for vertex in range(n):
                in_difference = ((current >> vertex) & 1) and not ((following >> vertex) & 1)
                if in_difference and distance[center][vertex] < next_distance:
                    bunch[center][vertex] = True

    return nearest, bunch


def _middle_even(lo: int, hi: int) -> int:
    candidates = [i for i in range(lo + 2, hi - 1) if i % 2 == 0]
    return min(candidates, key=lambda i: (abs(2 * i - lo - hi), i))


def _build_tree(source: int, n: int, lo: int, hi: int,
                nearest: list[list[int]], distance: list[list[int]]):
    """Store the source-specific split tree; leaves have span at most log2(K)."""
    nodes = []

    def build(left: int, right: int) -> int:
        node_index = len(nodes)
        node = {"lo": left, "hi": right, "mid": -1, "j": -1, "left": -1, "right": -1}
        nodes.append(node)
        if right - left <= BASE_SPAN:
            return node_index
        mid = _middle_even(left, right)
        candidates = range(left, mid - 1, 2)
        j = max(candidates, key=lambda level: (
            distance[source][nearest[level + 2][source]] - distance[source][nearest[level][source]],
            -level,
        ))
        node["mid"] = mid
        node["j"] = j
        node["left"] = build(left, j)
        node["right"] = build(mid, right)
        return node_index

    root = build(lo, hi)
    return nodes, root


def _dist_k(u: int, v: int, start: int, n: int, nearest: list[list[int]],
            bunch: list[list[bool]], distance: list[list[int]]) -> tuple[int, int]:
    level = start
    pivot = nearest[level][u]
    probes = 0
    while True:
        probes += 1
        if bunch[v][pivot]:
            return distance[u][pivot] + distance[v][pivot], probes
        if level + 1 >= K:
            raise AssertionError("A15 membership must terminate dist_k")
        u, v = v, u
        level += 1
        pivot = nearest[level][u]


def _query(u: int, v: int, nodes, root: int, n: int,
           nearest: list[list[int]], bunch: list[list[bool]],
           distance: list[list[int]]) -> tuple[int, int]:
    probes = 0
    node_index = root
    while nodes[node_index]["hi"] - nodes[node_index]["lo"] > BASE_SPAN:
        node = nodes[node_index]
        j = node["j"]
        first = bunch[v][nearest[j][u]]
        second = bunch[u][nearest[j + 1][v]]
        probes += 2
        node_index = node["right"] if not first and not second else node["left"]
    estimate, tail_probes = _dist_k(u, v, nodes[node_index]["lo"], n, nearest, bunch, distance)
    return estimate, probes + tail_probes


def _result(parsed):
    n, masks, edges, queries = parsed
    distance = _distances(n, edges)
    if any(distance[i][j] == INF for i in range(n) for j in range(n)):
        return None
    nearest, bunch = _prepare(n, masks, distance)
    staged = [len(queries)]
    for source, target in queries:
        if source == target:
            staged.extend((0, 0))
            continue
        nodes, root = _build_tree(source, n, 0, K - 1, nearest, distance)
        estimate, probes = _query(source, target, nodes, root, n, nearest, bunch, distance)
        staged.extend((estimate, probes))
    return tuple(staged)


def expected_output(
    values: tuple[int, ...] | list[int],
    output_capacity: int = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    values = tuple(values)
    if input_length is None:
        input_length = len(values)
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return INVALID_RESULT, b""
    staged = _result(parsed)
    if staged is None:
        return INVALID_RESULT, b""
    output = b"".join(struct.pack("<q", word) for word in staged)
    if output_is_null or output_capacity < len(output):
        return OUTPUT_ERROR, b""
    return len(output), output
