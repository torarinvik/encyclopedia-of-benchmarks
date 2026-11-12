"""Independent adjacency-list verifier for the bounded Baswana–Sen trace."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 8
MAX_M = 28
MAX_VALID_INPUT_LENGTH = 3 + 2 + 3 * MAX_M
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_M


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
    if any(mask < 0 or mask >= (1 << n) for mask in masks):
        return None
    offset = 3 + rounds
    edges = []
    seen = set()
    for i in range(m):
        u, v, weight = values[offset + 3 * i:offset + 3 * i + 3]
        if not 0 <= u < v < n or not 1 <= weight <= 32 or (u, v) in seen:
            return None
        seen.add((u, v))
        edges.append((u, v, weight))
    return n, k, masks, edges


def _rank(edges, edge_id):
    u, v, weight = edges[edge_id]
    return weight, u, v, edge_id


def _replay(n, masks, edges):
    incident = [[] for _ in range(n)]
    for edge_id, (u, v, _) in enumerate(edges):
        incident[u].append(edge_id)
        incident[v].append(edge_id)
    live = [True] * len(edges)
    keep = [0] * len(edges)
    owner = list(range(n))

    for sample_mask in masks:
        alive_centers = {c for c in owner if c >= 0}
        sampled = {c for c in alive_centers if sample_mask & (1 << c)}
        following = [-1] * n
        for vertex, center in enumerate(owner):
            if center in sampled:
                following[vertex] = center
        erase = set()

        for vertex in range(n):
            if owner[vertex] < 0 or owner[vertex] in sampled:
                continue
            incident_live = [edge_id for edge_id in incident[vertex] if live[edge_id]]
            sampled_edges = []
            for edge_id in incident_live:
                u, v, _ = edges[edge_id]
                neighbor = v if u == vertex else u
                if owner[neighbor] in sampled:
                    sampled_edges.append(edge_id)

            if sampled_edges:
                chosen = min(sampled_edges, key=lambda edge_id: _rank(edges, edge_id))
                u, v, weight = edges[chosen]
                neighbor = v if u == vertex else u
                landing = owner[neighbor]
                following[vertex] = landing
                keep[chosen] = 1

                by_cluster = {}
                for edge_id in incident_live:
                    a, b, _ = edges[edge_id]
                    neighbor = b if a == vertex else a
                    by_cluster.setdefault(owner[neighbor], []).append(edge_id)
                for center, group in by_cluster.items():
                    least = min(group, key=lambda edge_id: _rank(edges, edge_id))
                    if center == landing:
                        erase.update(group)
                    elif edges[least][2] < weight:
                        keep[least] = 1
                        erase.update(group)
            else:
                by_cluster = {}
                for edge_id in incident_live:
                    a, b, _ = edges[edge_id]
                    neighbor = b if a == vertex else a
                    by_cluster.setdefault(owner[neighbor], []).append(edge_id)
                for group in by_cluster.values():
                    least = min(group, key=lambda edge_id: _rank(edges, edge_id))
                    keep[least] = 1
                    erase.update(group)

        for edge_id in erase:
            live[edge_id] = False
        for edge_id, (u, v, _) in enumerate(edges):
            if live[edge_id] and following[u] >= 0 and following[u] == following[v]:
                live[edge_id] = False
        owner = following

    for vertex in range(n):
        if owner[vertex] < 0:
            continue
        by_cluster = {}
        for edge_id in incident[vertex]:
            if not live[edge_id]:
                continue
            u, v, _ = edges[edge_id]
            neighbor = v if u == vertex else u
            by_cluster.setdefault(owner[neighbor], []).append(edge_id)
        for group in by_cluster.values():
            keep[min(group, key=lambda edge_id: _rank(edges, edge_id))] = 1
    return bytes(keep)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    invalid, output_error = -1, -2
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return invalid, b""
    if input_is_null or values is None:
        return invalid, b""
    decoded = _decode(values)
    if decoded is None:
        return invalid, b""
    n, _, masks, edges = decoded
    payload = _replay(n, masks, edges)
    if output_is_null or capacity is not None and capacity < len(payload):
        return output_error, b""
    return len(payload), payload
