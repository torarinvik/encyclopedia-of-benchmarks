"""Oracle for the pinned weighted directed graph peripherality calculations."""

from __future__ import annotations

import struct

MAX_VERTICES = 8
MAX_EDGES = MAX_VERTICES * (MAX_VERTICES - 1)
MAX_WEIGHT = 1_000_000
INF = None


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or any(type(value) is not int for value in values)):
        return -1, b""
    node_count, edge_count = values[:2]
    if (not 1 <= node_count <= MAX_VERTICES or not 0 <= edge_count <= MAX_EDGES
            or len(values) != 2 + 3 * edge_count):
        return -1, b""
    distances: list[list[int | None]] = [[None] * node_count for _ in range(node_count)]
    for node in range(node_count):
        distances[node][node] = 0
    seen_edges: set[tuple[int, int]] = set()
    for offset in range(2, len(values), 3):
        source, destination, weight = values[offset:offset + 3]
        if (not 0 <= source < node_count or not 0 <= destination < node_count
                or source == destination or not 1 <= weight <= MAX_WEIGHT
                or (source, destination) in seen_edges):
            return -1, b""
        seen_edges.add((source, destination))
        distances[source][destination] = weight

    for middle in range(node_count):
        for source in range(node_count):
            first = distances[source][middle]
            if first is None:
                continue
            for destination in range(node_count):
                second = distances[middle][destination]
                if second is None:
                    continue
                candidate = first + second
                current = distances[source][destination]
                if current is None or candidate < current:
                    distances[source][destination] = candidate

    if node_count == 1:
        result = (0, 0, 0, 0)
    else:
        # The benchmark contract uses the strongly connected subset. This
        # keeps the source's infinite metrics for unreachable vertices out of
        # the portable signed-i64 output domain.
        if any(distances[source][destination] is None
               for source in range(node_count)
               for destination in range(node_count)):
            return -1, b""
        metrics: list[tuple[int | None, int | None]] = []
        any_reachable = False
        for source in range(node_count):
            reachable = [distances[source][destination] for destination in range(node_count)
                         if destination != source and distances[source][destination] not in (None, 0)]
            if not reachable:
                metrics.append((None, None))
                continue
            any_reachable = True
            finite = [distance for distance in reachable if distance is not None]
            metrics.append((max(finite), sum(finite)))
        peripheral = max(range(node_count), key=lambda node: (
            metrics[node][0] if metrics[node][0] is not None else -1,
            -node,
        ))
        far = max(range(node_count), key=lambda node: (
            metrics[node][1] if metrics[node][1] is not None else -1,
            -node,
        ))
        result = (peripheral, metrics[peripheral][0], far, metrics[far][1])
    data = struct.pack("<4q", *result)
    return len(data), data
