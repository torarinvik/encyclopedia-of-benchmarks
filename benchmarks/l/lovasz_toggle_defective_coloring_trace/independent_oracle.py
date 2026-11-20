"""Set-adjacency reference for deterministic Lovasz-toggle recoloring."""

from __future__ import annotations

from collections.abc import Sequence

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if type(input_is_null) is not bool or input_is_null:
        return -1
    if not isinstance(values, (list, tuple)) or not 5 <= len(values) <= 246:
        return -1
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return -1
    declared_length = len(values) if input_length is None else input_length
    if type(declared_length) is not int or declared_length != len(values):
        return -1

    n, red_limit, blue_limit, red_mask, edge_count = values[:5]
    if not 0 <= n <= 16 or not 1 <= red_limit <= 8 or not 1 <= blue_limit <= 8:
        return -1
    if not 0 <= red_mask < (1 << n):
        return -1
    if not 0 <= edge_count <= n * (n - 1) // 2 or len(values) != 5 + 2 * edge_count:
        return -1

    neighbors = [set() for _ in range(n)]
    for offset in range(5, len(values), 2):
        u, v = values[offset:offset + 2]
        if not 0 <= u < v < n or v in neighbors[u]:
            return -1
        neighbors[u].add(v)
        neighbors[v].add(u)
    if any(len(row) > red_limit + blue_limit + 1 for row in neighbors):
        return -1

    red = [(red_mask >> vertex) & 1 != 0 for vertex in range(n)]
    toggles = 0
    while True:
        chosen = None
        for vertex, row in enumerate(neighbors):
            same_color_neighbors = sum(red[other] == red[vertex] for other in row)
            permitted = red_limit if red[vertex] else blue_limit
            if same_color_neighbors > permitted:
                chosen = vertex
                break
        if chosen is None:
            break
        red[chosen] = not red[chosen]
        toggles += 1

    final_mask = sum((1 << vertex) for vertex, is_red in enumerate(red) if is_red)
    return (toggles << n) | final_mask
