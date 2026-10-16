"""Independent Floyd-Warshall oracle for the bounded Johnson benchmark."""

from __future__ import annotations

MAX_VERTICES = 32
MAX_EDGES = 256
MAX_INPUT_LENGTH = 2 + 3 * MAX_EDGES
MAX_WEIGHT = 32
UNREACHABLE_SENTINEL = 1 << 62
MIN_I64 = -(1 << 63)
MAX_I64 = (1 << 63) - 1
FNV_OFFSET_BASIS = 14695981039346656037
FNV_PRIME = 1099511628211
MASK_64 = (1 << 64) - 1
MASK_63 = (1 << 63) - 1


def _fnv_word(hash_value: int, word: int) -> int:
    bits = word & MASK_64
    for shift in range(0, 64, 8):
        hash_value ^= (bits >> shift) & 0xFF
        hash_value = (hash_value * FNV_PRIME) & MASK_64
    return hash_value


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Return the row-major distance checksum, or -1 for invalid input."""
    if not isinstance(values, (list, tuple)) or len(values) < 2 or len(values) > MAX_INPUT_LENGTH:
        return -1
    if any(type(value) is not int or not MIN_I64 <= value <= MAX_I64 for value in values):
        return -1

    vertices, edge_count = values[0], values[1]
    if not 1 <= vertices <= MAX_VERTICES or not 0 <= edge_count <= MAX_EDGES:
        return -1
    if len(values) != 2 + 3 * edge_count:
        return -1

    distances: list[list[int | None]] = [[None] * vertices for _ in range(vertices)]
    for vertex in range(vertices):
        distances[vertex][vertex] = 0

    for edge_index in range(edge_count):
        origin, destination, weight = values[2 + 3 * edge_index : 5 + 3 * edge_index]
        if not 1 <= origin <= vertices or not 1 <= destination <= vertices:
            return -1
        if not -MAX_WEIGHT <= weight <= MAX_WEIGHT:
            return -1
        left = origin - 1
        right = destination - 1
        previous = distances[left][right]
        if previous is None or weight < previous:
            distances[left][right] = weight

    for intermediate in range(vertices):
        for origin in range(vertices):
            first = distances[origin][intermediate]
            if first is None:
                continue
            for destination in range(vertices):
                second = distances[intermediate][destination]
                if second is None:
                    continue
                candidate = first + second
                current = distances[origin][destination]
                if current is None or candidate < current:
                    distances[origin][destination] = candidate

    if any(distances[vertex][vertex] is not None and distances[vertex][vertex] < 0 for vertex in range(vertices)):
        return -1

    result = FNV_OFFSET_BASIS
    for row in distances:
        for distance in row:
            result = _fnv_word(result, UNREACHABLE_SENTINEL if distance is None else distance)
    return result & MASK_63
