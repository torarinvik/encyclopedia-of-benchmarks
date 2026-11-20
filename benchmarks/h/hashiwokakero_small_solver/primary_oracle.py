"""Residual-degree backtracking reference for the bounded Hashiwokakero profile."""

from __future__ import annotations

from collections.abc import Sequence

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_ISLANDS = 6
MAX_EDGE_SLOTS = 12
MAX_CANDIDATE_EDGES = 7
MAX_VALID_INPUT_LENGTH = 19
MAX_PARSEABLE_INPUT_LENGTH = 20
SUCCESS_FLAG = 1 << 32
INVALID_RESULT = -1
UNSATISFIABLE_RESULT = -2


def _decode(values: Sequence[int] | None, input_is_null: bool = False,
            input_length: int | None = None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    count = values[0]
    if not 2 <= count <= MAX_ISLANDS or len(values) != 1 + 3 * count:
        return None
    x: list[int] = []
    y: list[int] = []
    demand: list[int] = []
    for island in range(count):
        px, py, required = values[1 + 3 * island:4 + 3 * island]
        if not 0 <= px <= 7 or not 0 <= py <= 7 or not 1 <= required <= 8:
            return None
        if any(px == x[prior] and py == y[prior] for prior in range(island)):
            return None
        x.append(px)
        y.append(py)
        demand.append(required)
    return count, x, y, demand


def _visible_edges(x: Sequence[int], y: Sequence[int]) -> list[tuple[int, int]]:
    count = len(x)
    edges: list[tuple[int, int]] = []
    for first in range(count):
        for second in range(first + 1, count):
            if x[first] != x[second] and y[first] != y[second]:
                continue
            blocked = False
            for middle in range(count):
                if middle == first or middle == second:
                    continue
                if y[first] == y[second] == y[middle]:
                    if min(x[first], x[second]) < x[middle] < max(x[first], x[second]):
                        blocked = True
                        break
                elif x[first] == x[second] == x[middle]:
                    if min(y[first], y[second]) < y[middle] < max(y[first], y[second]):
                        blocked = True
                        break
            if not blocked:
                edges.append((first, second))
    return edges


def _crosses(first: tuple[int, int], second: tuple[int, int],
             x: Sequence[int], y: Sequence[int]) -> bool:
    a, b = first
    c, d = second
    if y[a] == y[b] and x[c] == x[d]:
        return min(x[a], x[b]) < x[c] < max(x[a], x[b]) and min(y[c], y[d]) < y[a] < max(y[c], y[d])
    if x[a] == x[b] and y[c] == y[d]:
        return min(x[c], x[d]) < x[a] < max(x[c], x[d]) and min(y[a], y[b]) < y[c] < max(y[a], y[b])
    return False


def _potentially_connected(edges: Sequence[tuple[int, int]],
                           crossing: Sequence[Sequence[bool]],
                           multiplicity: Sequence[int],
                           assigned_through: int, island_count: int) -> bool:
    reached = [False] * island_count
    reached[0] = True
    stack = [0]
    while stack:
        island = stack.pop()
        for edge_index, (u, v) in enumerate(edges):
            if edge_index <= assigned_through:
                usable = multiplicity[edge_index] != 0
            else:
                usable = not any(
                    multiplicity[fixed] != 0 and crossing[fixed][edge_index]
                    for fixed in range(assigned_through + 1)
                )
            if not usable:
                continue
            neighbor = v if island == u else u if island == v else -1
            if neighbor >= 0 and not reached[neighbor]:
                reached[neighbor] = True
                stack.append(neighbor)
    return all(reached)


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _decode(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    island_count, x, y, demand = parsed
    edges = _visible_edges(x, y)
    if len(edges) > MAX_CANDIDATE_EDGES:
        return INVALID_RESULT
    edge_count = len(edges)
    crossing = [[False] * edge_count for _ in range(edge_count)]
    for first in range(edge_count):
        for second in range(first + 1, edge_count):
            crossing[first][second] = crossing[second][first] = _crosses(
                edges[first], edges[second], x, y)

    remaining_incident = [0] * island_count
    for u, v in edges:
        remaining_incident[u] += 1
        remaining_incident[v] += 1
    residual = list(demand)
    multiplicity = [0] * edge_count
    solution: list[int] | None = None

    def search(depth: int) -> bool:
        nonlocal solution
        if depth == edge_count:
            if any(value != 0 for value in residual):
                return False
            if not _potentially_connected(edges, crossing, multiplicity,
                                          edge_count - 1, island_count):
                return False
            solution = multiplicity.copy()
            return True

        u, v = edges[depth]
        remaining_incident[u] -= 1
        remaining_incident[v] -= 1
        for amount in range(3):
            if amount > residual[u] or amount > residual[v]:
                continue
            if any(multiplicity[prior] != 0 and crossing[prior][depth]
                   for prior in range(depth)):
                if amount != 0:
                    continue
            multiplicity[depth] = amount
            residual[u] -= amount
            residual[v] -= amount
            feasible_degrees = all(
                0 <= residual[island] <= 2 * remaining_incident[island]
                for island in range(island_count)
            )
            if (feasible_degrees
                    and _potentially_connected(edges, crossing, multiplicity,
                                               depth, island_count)
                    and search(depth + 1)):
                residual[u] += amount
                residual[v] += amount
                remaining_incident[u] += 1
                remaining_incident[v] += 1
                return True
            residual[u] += amount
            residual[v] += amount
            multiplicity[depth] = 0
        remaining_incident[u] += 1
        remaining_incident[v] += 1
        return False

    if not search(0) or solution is None:
        return UNSATISFIABLE_RESULT
    result = SUCCESS_FLAG
    for edge_index, amount in enumerate(solution):
        result |= amount << (2 * edge_index)
    return result
