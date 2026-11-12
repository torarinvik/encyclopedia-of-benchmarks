"""Primary bounded trace oracle for Baswana–Sen weighted spanner Algorithm II."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 8
MAX_M = 28
MAX_VALID_INPUT_LENGTH = 3 + 2 + 3 * MAX_M
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_M
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _decode(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, m, k = values[:3]
    if not 2 <= n <= MAX_N or not 0 <= m <= MAX_M or not 2 <= k <= 3:
        return None
    rounds = k - 1
    if len(values) != 3 + rounds + 3 * m:
        return None
    masks = list(values[3:3 + rounds])
    if any(mask < 0 or mask >= 1 << n for mask in masks):
        return None
    edges: list[tuple[int, int, int]] = []
    seen: set[tuple[int, int]] = set()
    offset = 3 + rounds
    for index in range(m):
        u, v, weight = values[offset + 3 * index:offset + 3 * index + 3]
        if (not 0 <= u < v < n or not 1 <= weight <= 32
                or (u, v) in seen):
            return None
        seen.add((u, v))
        edges.append((u, v, weight))
    return n, k, masks, edges


def _edge_key(edge: tuple[int, int, int], index: int) -> tuple[int, int, int, int]:
    u, v, weight = edge
    return weight, u, v, index


def _selected(n: int, k: int, masks: list[int],
              edges: list[tuple[int, int, int]]) -> bytes:
    active = [True] * len(edges)
    selected = [0] * len(edges)
    cluster = list(range(n))

    for mask in masks:
        sampled = [False] * n
        for center in cluster:
            if center >= 0 and mask >> center & 1:
                sampled[center] = True
        next_cluster = [-1] * n
        for vertex in range(n):
            center = cluster[vertex]
            if center >= 0 and sampled[center]:
                next_cluster[vertex] = center

        remove = [False] * len(edges)
        for vertex in range(n):
            old_center = cluster[vertex]
            if old_center < 0 or sampled[old_center]:
                continue

            best_sampled = -1
            for index, edge in enumerate(edges):
                if not active[index] or vertex not in edge[:2]:
                    continue
                other = edge[1] if edge[0] == vertex else edge[0]
                other_center = cluster[other]
                if other_center >= 0 and sampled[other_center] and (
                    best_sampled < 0
                    or _edge_key(edge, index) < _edge_key(edges[best_sampled], best_sampled)
                ):
                    best_sampled = index

            if best_sampled < 0:
                group_centers = sorted({
                    cluster[edge[1] if edge[0] == vertex else edge[0]]
                    for index, edge in enumerate(edges)
                    if active[index] and vertex in edge[:2]
                } - {-1})
                for neighbor_center in group_centers:
                    group = [
                        index for index, edge in enumerate(edges)
                        if active[index] and vertex in edge[:2]
                        and cluster[edge[1] if edge[0] == vertex else edge[0]] == neighbor_center
                    ]
                    if group:
                        least = min(group, key=lambda i: _edge_key(edges[i], i))
                        selected[least] = 1
                        for index in group:
                            remove[index] = True
                continue

            edge = edges[best_sampled]
            other = edge[1] if edge[0] == vertex else edge[0]
            chosen_center = cluster[other]
            next_cluster[vertex] = chosen_center
            selected[best_sampled] = 1
            for index, candidate in enumerate(edges):
                if not active[index] or vertex not in candidate[:2]:
                    continue
                neighbor = candidate[1] if candidate[0] == vertex else candidate[0]
                if cluster[neighbor] == chosen_center:
                    remove[index] = True

            group_centers = sorted({
                cluster[candidate[1] if candidate[0] == vertex else candidate[0]]
                for index, candidate in enumerate(edges)
                if active[index] and vertex in candidate[:2]
            } - {-1})
            for neighbor_center in group_centers:
                if neighbor_center == chosen_center:
                    continue
                group = [
                    index for index, candidate in enumerate(edges)
                    if active[index] and vertex in candidate[:2]
                    and cluster[candidate[1] if candidate[0] == vertex else candidate[0]] == neighbor_center
                ]
                if not group:
                    continue
                least = min(group, key=lambda i: _edge_key(edges[i], i))
                if edges[least][2] < edge[2]:
                    selected[least] = 1
                    for index in group:
                        remove[index] = True

        for index in range(len(edges)):
            if remove[index]:
                active[index] = False
        for index, (u, v, _) in enumerate(edges):
            if (active[index] and next_cluster[u] >= 0
                    and next_cluster[u] == next_cluster[v]):
                active[index] = False
        cluster = next_cluster

    # Vertex-to-cluster joining: each vertex contributes the least active
    # incident edge for each neighboring final cluster.
    for vertex in range(n):
        if cluster[vertex] < 0:
            continue
        neighbor_centers = sorted({
            cluster[edge[1] if edge[0] == vertex else edge[0]]
            for index, edge in enumerate(edges)
            if active[index] and vertex in edge[:2]
        } - {-1})
        for neighbor_center in neighbor_centers:
            group = [
                index for index, edge in enumerate(edges)
                if active[index] and vertex in edge[:2]
                and cluster[edge[1] if edge[0] == vertex else edge[0]] == neighbor_center
            ]
            if group:
                selected[min(group, key=lambda i: _edge_key(edges[i], i))] = 1
    return bytes(selected)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    decoded = _decode(values)
    if decoded is None:
        return INVALID_RESULT, b""
    n, k, masks, edges = decoded
    payload = _selected(n, k, masks, edges)
    if output_is_null or capacity is not None and capacity < len(payload):
        return OUTPUT_ERROR, b""
    return len(payload), payload
