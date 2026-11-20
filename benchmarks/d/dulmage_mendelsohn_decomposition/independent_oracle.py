"""Exhaustive maximum-matching reference for Dulmage--Mendelsohn classes."""

from __future__ import annotations

from collections.abc import Sequence

try:
    from .primary_oracle import (
        INVALID_RESULT, MAX_EDGES, MAX_PARSEABLE_INPUT_LENGTH, MAX_RESULT, MAX_SIDE,
    )
except ImportError:
    from primary_oracle import (
        INVALID_RESULT, MAX_EDGES, MAX_PARSEABLE_INPUT_LENGTH, MAX_RESULT, MAX_SIDE,
    )


def _read(values: Sequence[int] | None, input_is_null: bool,
          input_length: int | None) -> tuple[int, int, list[set[int]]] | None:
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n_left, n_right, m = values[0], values[1], values[2]
    if (not 0 <= n_left <= MAX_SIDE or not 0 <= n_right <= MAX_SIDE
            or n_left + n_right == 0 or not 0 <= m <= MAX_EDGES
            or m > n_left * n_right or len(values) != 3 + 2 * m):
        return None
    neighbors = [set() for _ in range(n_left)]
    for edge_index in range(m):
        u = values[3 + 2 * edge_index]
        v = values[4 + 2 * edge_index]
        if not 0 <= u < n_left or not 0 <= v < n_right or v in neighbors[u]:
            return None
        neighbors[u].add(v)
    return n_left, n_right, neighbors


def _all_optima_partition(n_left: int, n_right: int,
                          neighbors: list[set[int]]) -> tuple[int, list[int]]:
    best_size = -1
    exposable = 0

    def enumerate_matchings(left: int, used_right: int,
                            used_left: int, size: int) -> None:
        nonlocal best_size, exposable
        if left == n_left:
            exposed = (sum(1 << u for u in range(n_left) if not (used_left >> u) & 1)
                       | (sum(1 << (n_left + v) for v in range(n_right)
                              if not (used_right >> v) & 1)))
            if size > best_size:
                best_size = size
                exposable = exposed
            elif size == best_size:
                exposable |= exposed
            return
        enumerate_matchings(left + 1, used_right, used_left, size)
        for right in sorted(neighbors[left]):
            bit = 1 << right
            if used_right & bit:
                continue
            enumerate_matchings(left + 1, used_right | bit,
                                used_left | (1 << left), size + 1)

    enumerate_matchings(0, 0, 0, 0)
    total = n_left + n_right
    odd = 0
    for left, rights in enumerate(neighbors):
        if exposable & (1 << left):
            for right in rights:
                odd |= 1 << (n_left + right)
    for right in range(n_right):
        global_right = n_left + right
        if exposable & (1 << global_right):
            for left, rights in enumerate(neighbors):
                if right in rights:
                    odd |= 1 << left
    classes = []
    for vertex in range(total):
        if exposable & (1 << vertex):
            classes.append(0)
        elif odd & (1 << vertex):
            classes.append(1)
        else:
            classes.append(2)
    return best_size, classes


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _read(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n_left, n_right, neighbors = parsed
    matching_size, classes = _all_optima_partition(n_left, n_right, neighbors)
    packed = matching_size << 32
    for vertex, code in enumerate(classes):
        packed |= code << (2 * vertex)
    return packed if 0 <= packed <= MAX_RESULT else INVALID_RESULT
