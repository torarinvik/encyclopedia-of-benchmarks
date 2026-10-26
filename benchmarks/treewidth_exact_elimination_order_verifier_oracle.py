"""Independent bitset verifier for exhaustive minimum-width elimination order."""

from __future__ import annotations

from collections.abc import Sequence


def _encode(words: list[int]) -> bytes:
    out = bytearray()
    for word in words:
        out.extend(word.to_bytes(8, "little", signed=True))
    return bytes(out)


def _next_permutation(order: list[int]) -> bool:
    pivot = len(order) - 2
    while pivot >= 0 and order[pivot] >= order[pivot + 1]:
        pivot -= 1
    if pivot < 0:
        return False
    successor = len(order) - 1
    while order[successor] <= order[pivot]:
        successor -= 1
    order[pivot], order[successor] = order[successor], order[pivot]
    order[pivot + 1:] = reversed(order[pivot + 1:])
    return True


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or input_is_null or values is None or not isinstance(values, (tuple, list))
            or len(values) < 2 or len(values) > 58
            or input_length is not None and
                (type(input_length) is not int or input_length != len(values))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    n, edge_count = values[0], values[1]
    if not 1 <= n <= 8 or not 0 <= edge_count <= min(28, n * (n - 1) // 2):
        return -1, b""
    if len(values) != 2 + 2 * edge_count:
        return -1, b""
    adjacency = [0] * n
    for edge in range(edge_count):
        left, right = values[2 + 2 * edge:4 + 2 * edge]
        if not 0 <= left < right < n or adjacency[left] >> right & 1:
            return -1, b""
        adjacency[left] |= 1 << right
        adjacency[right] |= 1 << left

    order = list(range(n))
    best_width = n + 1
    best_order: list[int] | None = None
    while True:
        work = adjacency[:]
        alive = (1 << n) - 1
        width = 0
        for vertex in order:
            neighbors = work[vertex] & alive
            width = max(width, neighbors.bit_count())
            remaining = neighbors
            while remaining:
                low = remaining & -remaining
                left = low.bit_length() - 1
                later = remaining ^ low
                while later:
                    bit = later & -later
                    right = bit.bit_length() - 1
                    work[left] |= 1 << right
                    work[right] |= 1 << left
                    later ^= bit
                remaining ^= low
            alive &= ~(1 << vertex)
        if width < best_width:
            best_width = width
            best_order = order[:]
        if not _next_permutation(order):
            break
    assert best_order is not None
    payload = _encode([best_width, *best_order])
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < len(payload):
        return -2, b""
    return len(payload), payload
