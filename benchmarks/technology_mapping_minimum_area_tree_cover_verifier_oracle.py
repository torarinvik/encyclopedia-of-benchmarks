"""Independent recursive oracle for the small tree-covering profile."""

from __future__ import annotations

from collections.abc import Sequence
from functools import lru_cache

MAX_N = 31


def _parse(values, input_is_null, input_length):
    if (input_is_null or not isinstance(values, (list, tuple)) or len(values) < 9 or len(values) > 99
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != 6 + 3 * n:
        return None
    costs = tuple(values[1:6])
    if any(c != -1 and not 1 <= c <= 1_000_000 for c in costs):
        return None
    nodes = tuple(tuple(values[6 + 3 * v:9 + 3 * v]) for v in range(n))
    indegree = [0] * n
    for vertex, (kind, left, right) in enumerate(nodes):
        children = () if kind == 0 else (left,) if kind == 1 else (left, right) if kind == 2 else None
        if children is None:
            return None
        if kind == 0 and (left != -1 or right != -1):
            return None
        if kind == 1 and right != -1:
            return None
        for child in children:
            if not vertex < child < n:
                return None
            indegree[child] += 1
        if len(children) == 2 and left == right:
            return None
    if indegree[0] or any(value != 1 for value in indegree[1:]):
        return None
    return n, costs, nodes


def _solve(parsed):
    n, costs, nodes = parsed

    @lru_cache(maxsize=None)
    def minimum(vertex):
        kind, left, right = nodes[vertex]
        if kind == 0:
            return 0, -1
        candidates = []
        if kind == 1:
            child_cost = minimum(left)[0]
            if costs[0] >= 0 and child_cost is not None:
                candidates.append((costs[0] + child_cost, 0))
        else:
            left_cost, right_cost = minimum(left)[0], minimum(right)[0]
            if costs[1] >= 0 and left_cost is not None and right_cost is not None:
                candidates.append((costs[1] + left_cost + right_cost, 1))
            if costs[2] >= 0 and nodes[left][0] == 1 and left_cost is not None:
                cut_cost = minimum(nodes[left][1])[0]
                if cut_cost is not None and right_cost is not None:
                    candidates.append((costs[2] + cut_cost + right_cost, 2))
            if costs[3] >= 0 and nodes[right][0] == 1 and right_cost is not None:
                cut_cost = minimum(nodes[right][1])[0]
                if left_cost is not None and cut_cost is not None:
                    candidates.append((costs[3] + left_cost + cut_cost, 3))
            if costs[4] >= 0 and nodes[left][0] == 1 and nodes[right][0] == 1:
                left_cut = minimum(nodes[left][1])[0]
                right_cut = minimum(nodes[right][1])[0]
                if left_cut is not None and right_cut is not None:
                    candidates.append((costs[4] + left_cut + right_cut, 4))
        return min(candidates) if candidates else (None, -1)

    root_cost = minimum(0)[0]
    if root_cost is None:
        return None
    output = [-1 if node[0] == 0 else -3 for node in nodes]

    def emit(vertex):
        pattern = minimum(vertex)[1]
        output[vertex] = pattern
        kind, left, right = nodes[vertex]
        if pattern == 0:
            emit(left)
        elif pattern == 1:
            emit(left); emit(right)
        elif pattern == 2:
            output[left] = -2; emit(nodes[left][1]); emit(right)
        elif pattern == 3:
            output[right] = -2; emit(left); emit(nodes[right][1])
        elif pattern == 4:
            output[left] = -2; output[right] = -2
            emit(nodes[left][1]); emit(nodes[right][1])

    if nodes[0][0] != 0:
        emit(0)
    return [root_cost, *output]


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    parsed = _parse(values, input_is_null, input_length)
    result = None if parsed is None else _solve(parsed)
    if result is None:
        return -1, b""
    payload = b"".join(int(x).to_bytes(8, "little", signed=True) for x in result)
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < len(payload):
        return -2, b""
    return len(payload), payload
