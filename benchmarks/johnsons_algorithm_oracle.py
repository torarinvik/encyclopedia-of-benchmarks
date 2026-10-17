"""Independent Floyd-Warshall oracle for bounded Java Johnson's algorithm."""

from __future__ import annotations

MAX_VERTICES = 16
MAX_WEIGHT = 32
MAX_INPUT_LENGTH = 1 + MAX_VERTICES * MAX_VERTICES
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


def _strongly_connected(adjacency: list[list[int | None]]) -> bool:
    vertices = len(adjacency)
    for start in range(vertices):
        reached = {start}
        pending = [start]
        while pending:
            current = pending.pop()
            for destination, weight in enumerate(adjacency[current]):
                if weight is not None and destination not in reached:
                    reached.add(destination)
                    pending.append(destination)
        if len(reached) != vertices:
            return False
    return True


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Return the all-pairs distance checksum, or -1 outside the reviewed domain."""
    if (not isinstance(values, (list, tuple)) or not values
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not MIN_I64 <= value <= MAX_I64
                   for value in values)):
        return -1

    vertices = values[0]
    if not 1 <= vertices <= MAX_VERTICES or len(values) != 1 + vertices * vertices:
        return -1
    if any(not -MAX_WEIGHT <= value <= MAX_WEIGHT for value in values[1:]):
        return -1

    adjacency: list[list[int | None]] = [[None] * vertices for _ in range(vertices)]
    distances: list[list[int | None]] = [[None] * vertices for _ in range(vertices)]
    for vertex in range(vertices):
        distances[vertex][vertex] = 0
        for destination in range(vertices):
            weight = values[1 + vertex * vertices + destination]
            if vertex != destination and weight != 0:
                adjacency[vertex][destination] = weight
                distances[vertex][destination] = weight

    if not _strongly_connected(adjacency):
        return -1

    edges = [(origin, destination, weight)
             for origin, row in enumerate(adjacency)
             for destination, weight in enumerate(row)
             if weight is not None]
    potential = [0] * vertices
    for _ in range(vertices - 1):
        updated = False
        for origin, destination, weight in edges:
            candidate = potential[origin] + weight
            if candidate < potential[destination]:
                potential[destination] = candidate
                updated = True
        if not updated:
            break
    if any(potential[origin] + weight < potential[destination]
           for origin, destination, weight in edges):
        return -1
    if any(weight + potential[origin] - potential[destination] <= 0
           for origin, destination, weight in edges):
        return -1

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

    result = FNV_OFFSET_BASIS
    for row in distances:
        for distance in row:
            result = _fnv_word(
                result,
                UNREACHABLE_SENTINEL if distance is None else distance,
            )
    return result & MASK_63
