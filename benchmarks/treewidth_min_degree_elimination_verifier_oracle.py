"""Independent bitset oracle for bounded minimum-degree elimination."""

from __future__ import annotations

from collections.abc import Sequence


def _encode(words: list[int]) -> bytes:
    result = bytearray()
    for word in words:
        result.extend(word.to_bytes(8, "little", signed=True))
    return bytes(result)


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
    n, count = values[0], values[1]
    if not 1 <= n <= 16 or not 0 <= count <= min(120, n * (n - 1) // 2):
        return -1, b""
    if len(values) != 2 + 2 * count:
        return -1, b""
    adjacency = [0] * n
    for index in range(count):
        a, b = values[2 + index * 2:4 + index * 2]
        if not 0 <= a < b < n or adjacency[a] >> b & 1:
            return -1, b""
        adjacency[a] |= 1 << b
        adjacency[b] |= 1 << a

    alive = (1 << n) - 1
    sequence: list[int] = []
    added: list[tuple[int, int]] = []
    largest_bag_minus_one = 0
    for _ in range(n):
        # Select the minimum (degree, vertex id) pair independently of the matrix oracle.
        chosen = min(range(n), key=lambda v: ((adjacency[v] & alive).bit_count(), v))
        largest_bag_minus_one = max(largest_bag_minus_one, (adjacency[chosen] & alive).bit_count())
        sequence.append(chosen)
        neighbors_mask = adjacency[chosen] & alive
        neighbors = [v for v in range(n) if neighbors_mask >> v & 1]
        for i, a in enumerate(neighbors):
            for b in neighbors[i + 1:]:
                if not (adjacency[a] >> b & 1):
                    adjacency[a] |= 1 << b
                    adjacency[b] |= 1 << a
                    added.append((a, b))
        alive &= ~(1 << chosen)
    words = [largest_bag_minus_one, *sequence, len(added)]
    for a, b in added:
        words.extend((a, b))
    payload = _encode(words)
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < len(payload):
        return -2, b""
    return len(payload), payload
