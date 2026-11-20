"""Catalan triangulation-enumeration reference for the additive objective."""

from __future__ import annotations

from collections.abc import Sequence
from functools import lru_cache

MIN_VERTICES = 3
MAX_VERTICES = 10
MAX_DIAGONAL_WEIGHT = 1000
MAX_VALID_INPUT_LENGTH = 36
MAX_PARSEABLE_INPUT_LENGTH = 37
WORKSPACE_BYTES = 2048
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, dict[tuple[int, int], int]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return None
    n = values[0]
    if not MIN_VERTICES <= n <= MAX_VERTICES:
        return None
    diagonals = tuple(
        (i, j)
        for i in range(n)
        for j in range(i + 2, n)
        if not (i == 0 and j == n - 1)
    )
    if len(values) != 1 + len(diagonals):
        return None
    weights: dict[tuple[int, int], int] = {}
    for edge, weight in zip(diagonals, values[1:]):
        if not 0 <= weight <= MAX_DIAGONAL_WEIGHT:
            return None
        weights[edge] = weight
    return n, weights


def _internal_edge(i: int, j: int, n: int) -> tuple[int, int] | None:
    if j - i == 1 or (i == 0 and j == n - 1):
        return None
    return (i, j)


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Enumerate complete triangulations and minimize their diagonal-set score."""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, weights = parsed

    @lru_cache(maxsize=None)
    def triangulations(left: int, right: int) -> tuple[frozenset[tuple[int, int]], ...]:
        if right - left < 2:
            return (frozenset(),)
        outcomes: list[frozenset[tuple[int, int]]] = []
        for split in range(left + 1, right):
            triangle_edges = {
                edge for edge in (
                    _internal_edge(left, split, n),
                    _internal_edge(split, right, n),
                    _internal_edge(left, right, n),
                ) if edge is not None
            }
            for before in triangulations(left, split):
                for after in triangulations(split, right):
                    outcomes.append(before | after | triangle_edges)
        return tuple(outcomes)

    scores = (sum(weights[edge] for edge in diagonal)
              for diagonal in triangulations(0, n - 1))
    return min(scores)


expected_output = expected_result
