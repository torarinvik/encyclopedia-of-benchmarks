"""Factorial permutation oracle for minimum directed feedback arc set."""

from __future__ import annotations

from collections.abc import Sequence
from itertools import permutations

from .primary_oracle import INVALID_RESULT, MAX_EDGES, MAX_PARSEABLE_INPUT_LENGTH, MAX_VERTICES


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return INVALID_RESULT
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return INVALID_RESULT
    n, m = values[0], values[1]
    if not 1 <= n <= MAX_VERTICES or not 0 <= m <= MAX_EDGES:
        return INVALID_RESULT
    if input_length != 2 + 2 * m:
        return INVALID_RESULT
    arcs: list[tuple[int, int]] = []
    seen: set[tuple[int, int]] = set()
    for edge in range(m):
        tail, head = values[2 + 2 * edge:4 + 2 * edge]
        arc = (tail, head)
        if not 0 <= tail < n or not 0 <= head < n or tail == head or arc in seen:
            return INVALID_RESULT
        seen.add(arc)
        arcs.append(arc)

    best = m
    for order in permutations(range(n)):
        position = [0] * n
        for index, vertex in enumerate(order):
            position[vertex] = index
        backward = 0
        for tail, head in arcs:
            if position[tail] > position[head]:
                backward += 1
        if backward < best:
            best = backward
    return best


def verify_candidate(values: Sequence[int] | None, result: int,
                     input_is_null: bool = False,
                     input_length: int | None = None) -> bool:
    return (type(result) is int
            and result == expected_result(values, input_is_null, input_length))
