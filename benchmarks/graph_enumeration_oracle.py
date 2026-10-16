"""Oracle for bounded sorted-label graph adjacency enumeration."""

from __future__ import annotations

MAX_VERTICES = 16
MAX_DEGREE = 32
MAX_LABEL = 1_000_000
MAX_INPUT_LENGTH = 1 + MAX_VERTICES + MAX_VERTICES * (1 + MAX_DEGREE)
MASK64 = (1 << 64) - 1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if not isinstance(values, (list, tuple)) or not values or any(type(x) is not int for x in values):
        return -1
    n = values[0]
    if not 0 <= n <= MAX_VERTICES or len(values) < 1 + n:
        return -1
    labels = list(values[1:1 + n])
    if any(not -MAX_LABEL <= x <= MAX_LABEL for x in labels) or len(set(labels)) != n:
        return -1
    ordered = sorted(labels)
    ordinal = {label: i + 1 for i, label in enumerate(ordered)}
    offset = 1 + n
    adjacency: dict[int, list[int]] = {}
    for _ in range(n):
        if offset >= len(values):
            return -1
        degree = values[offset]
        offset += 1
        if not 0 <= degree <= MAX_DEGREE or offset + degree > len(values):
            return -1
        neighbors = values[offset:offset + degree]
        offset += degree
        if any(label not in ordinal for label in neighbors):
            return -1
        adjacency[labels[_]] = neighbors
    if offset != len(values):
        return -1
    rows = [[]] + [[ordinal[x] for x in adjacency[label]] for label in ordered]
    encoded = [len(rows)]
    for row in rows:
        encoded.append(len(row))
        encoded.extend(row)
    h = 14695981039346656037
    for value in encoded:
        bits = value & MASK64
        for _ in range(8):
            h = ((h ^ (bits & 255)) * 1099511628211) & MASK64
            bits >>= 8
    return h if h < (1 << 63) else h - (1 << 64)
