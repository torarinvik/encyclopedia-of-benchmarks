"""Portable oracle for weighted directed graph centrality."""

from __future__ import annotations

import struct

MAX_NODES = 16
MAX_EDGE_WEIGHT = 1_000_000
MAX_OUTPUT_BYTES = 16


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or any(type(value) is not int for value in values)):
        return -1, b""
    node_count, edge_count = values[:2]
    if (not 1 <= node_count <= MAX_NODES
            or not 0 <= edge_count <= node_count * (node_count - 1)
            or len(values) != 2 + 3 * edge_count):
        return -1, b""

    distances: list[list[int | None]] = [
        [0 if source == target else None for target in range(node_count)]
        for source in range(node_count)
    ]
    for offset in range(2, len(values), 3):
        source, target, weight = values[offset:offset + 3]
        if (not 0 <= source < node_count or not 0 <= target < node_count
                or source == target or not 1 <= weight <= MAX_EDGE_WEIGHT
                or distances[source][target] is not None):
            return -1, b""
        distances[source][target] = weight

    for intermediate in range(node_count):
        for source in range(node_count):
            first_leg = distances[source][intermediate]
            if first_leg is None:
                continue
            for target in range(node_count):
                second_leg = distances[intermediate][target]
                if second_leg is None:
                    continue
                candidate = first_leg + second_leg
                current = distances[source][target]
                if current is None or candidate < current:
                    distances[source][target] = candidate

    central_node = -1
    median_node = -1
    best_eccentricity: int | None = None
    best_harmonic_closeness: float | None = None
    if node_count == 1:
        central_node = median_node = 0
    else:
        for source in range(node_count):
            reachable = [
                distances[source][target]
                for target in range(node_count)
                if target != source and distances[source][target] is not None
            ]
            if not reachable:
                continue
            eccentricity = max(reachable)
            harmonic_closeness = sum(1.0 / distance for distance in reachable)
            if best_eccentricity is None or eccentricity < best_eccentricity:
                best_eccentricity = eccentricity
                central_node = source
            if (best_harmonic_closeness is None
                    or harmonic_closeness > best_harmonic_closeness):
                best_harmonic_closeness = harmonic_closeness
                median_node = source

    output = struct.pack("<qq", central_node, median_node)
    return len(output), output
