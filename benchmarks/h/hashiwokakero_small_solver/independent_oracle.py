"""Exhaustive complete-vector reference, independent of constrained search."""

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


def _valid_input(values: Sequence[int] | None, input_is_null: bool,
                 input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    n = values[0]
    if not 2 <= n <= MAX_ISLANDS or len(values) != 1 + 3 * n:
        return None
    islands = []
    for index in range(n):
        x, y, degree = values[1 + 3 * index:4 + 3 * index]
        if not (0 <= x <= 7 and 0 <= y <= 7 and 1 <= degree <= 8):
            return None
        if any(x == old_x and y == old_y for old_x, old_y, _ in islands):
            return None
        islands.append((x, y, degree))
    return islands


def _candidate_pairs(islands):
    pairs = []
    for i in range(len(islands)):
        for j in range(i + 1, len(islands)):
            x1, y1, _ = islands[i]
            x2, y2, _ = islands[j]
            if x1 != x2 and y1 != y2:
                continue
            has_middle = False
            for k, (x, y, _) in enumerate(islands):
                if k == i or k == j:
                    continue
                if y1 == y2 == y and min(x1, x2) < x < max(x1, x2):
                    has_middle = True
                if x1 == x2 == x and min(y1, y2) < y < max(y1, y2):
                    has_middle = True
            if not has_middle:
                pairs.append((i, j))
    return pairs


def _interior_crossing(first, second, islands) -> bool:
    a, b = first
    c, d = second
    ax, ay, _ = islands[a]
    bx, by, _ = islands[b]
    cx, cy, _ = islands[c]
    dx, dy, _ = islands[d]
    if ay == by and cx == dx:
        return min(ax, bx) < cx < max(ax, bx) and min(cy, dy) < ay < max(cy, dy)
    if ax == bx and cy == dy:
        return min(cx, dx) < ax < max(cx, dx) and min(ay, by) < cy < max(ay, by)
    return False


def _is_solution(vector, pairs, islands) -> bool:
    degree_sum = [0] * len(islands)
    adjacency = [[] for _ in islands]
    for edge_index, amount in enumerate(vector):
        if amount == 0:
            continue
        u, v = pairs[edge_index]
        degree_sum[u] += amount
        degree_sum[v] += amount
        adjacency[u].append(v)
        adjacency[v].append(u)
    if any(degree_sum[i] != islands[i][2] for i in range(len(islands))):
        return False
    for first in range(len(pairs)):
        if vector[first] == 0:
            continue
        for second in range(first + 1, len(pairs)):
            if vector[second] != 0 and _interior_crossing(
                    pairs[first], pairs[second], islands):
                return False
    seen = {0}
    stack = [0]
    while stack:
        for neighbor in adjacency[stack.pop()]:
            if neighbor not in seen:
                seen.add(neighbor)
                stack.append(neighbor)
    return len(seen) == len(islands)


def expected_result(values: Sequence[int] | None,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    islands = _valid_input(values, input_is_null, input_length)
    if islands is None:
        return INVALID_RESULT
    pairs = _candidate_pairs(islands)
    if len(pairs) > MAX_CANDIDATE_EDGES:
        return INVALID_RESULT
    edge_count = len(pairs)
    vector_count = 3 ** edge_count
    for encoded in range(vector_count):
        # The first edge is the most-significant trit, so increasing encoded
        # values scan multiplicity vectors in lexicographic edge order.
        vector = [
            (encoded // (3 ** (edge_count - edge_index - 1))) % 3
            for edge_index in range(edge_count)
        ]
        if _is_solution(vector, pairs, islands):
            result = SUCCESS_FLAG
            for edge_index, amount in enumerate(vector):
                result |= amount << (2 * edge_index)
            return result
    return UNSATISFIABLE_RESULT
