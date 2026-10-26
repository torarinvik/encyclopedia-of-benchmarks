"""Independent bitset verifier oracle for minimum-fill elimination."""

from __future__ import annotations

from collections.abc import Sequence


def _encode(words: list[int]) -> bytes:
    output = bytearray()
    for word in words:
        output.extend(word.to_bytes(8, "little", signed=True))
    return bytes(output)


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or input_is_null or values is None or not isinstance(values, (list, tuple))
            or len(values) < 2 or len(values) > 242
            or input_length is not None and
                (type(input_length) is not int or input_length != len(values))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    n, edge_count = values[0], values[1]
    if not 1 <= n <= 16 or not 0 <= edge_count <= min(120, n * (n - 1) // 2):
        return -1, b""
    if len(values) != 2 + 2 * edge_count:
        return -1, b""
    adjacency = [0] * n
    for index in range(edge_count):
        a, b = values[2 + 2 * index:4 + 2 * index]
        if not 0 <= a < b < n or adjacency[a] >> b & 1:
            return -1, b""
        adjacency[a] |= 1 << b
        adjacency[b] |= 1 << a

    alive = (1 << n) - 1
    order: list[int] = []
    added: list[tuple[int, int]] = []
    maximum_degree = 0
    while alive:
        best: tuple[int, int, int] | None = None
        for vertex in range(n):
            if not alive >> vertex & 1:
                continue
            neighbors = adjacency[vertex] & alive
            missing = 0
            remaining = neighbors
            while remaining:
                low = remaining & -remaining
                left = low.bit_length() - 1
                later = remaining ^ low
                while later:
                    bit = later & -later
                    right = bit.bit_length() - 1
                    if not (adjacency[left] >> right & 1):
                        missing += 1
                    later ^= bit
                remaining ^= low
            candidate = (missing, vertex, neighbors.bit_count())
            if best is None or candidate[:2] < best[:2]:
                best = candidate
        assert best is not None
        _, chosen, degree = best
        maximum_degree = max(maximum_degree, degree)
        order.append(chosen)
        neighbors_mask = adjacency[chosen] & alive
        neighbors = [vertex for vertex in range(n) if neighbors_mask >> vertex & 1]
        for i, a in enumerate(neighbors):
            for b in neighbors[i + 1:]:
                if not (adjacency[a] >> b & 1):
                    adjacency[a] |= 1 << b
                    adjacency[b] |= 1 << a
                    added.append((a, b))
        alive &= ~(1 << chosen)
    words = [maximum_degree, *order, len(added)]
    for a, b in added:
        words.extend((a, b))
    payload = _encode(words)
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < len(payload):
        return -2, b""
    return len(payload), payload
