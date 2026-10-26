"""Primary bottom-up oracle for the bounded minimum-area tree-cover profile."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 31
MAX_INPUT = 6 + 3 * MAX_N
MAX_OUTPUT = 8 * (MAX_N + 1)
PATTERN_COSTS = 5


def _parse(values: Sequence[int] | None, input_is_null: bool, input_length: int | None):
    if (input_is_null or not isinstance(values, (list, tuple)) or len(values) < 9
            or len(values) > MAX_INPUT
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != 6 + 3 * n:
        return None
    costs = values[1:6]
    if any(cost != -1 and not 1 <= cost <= 1_000_000 for cost in costs):
        return None
    nodes = [tuple(values[6 + 3 * i:9 + 3 * i]) for i in range(n)]
    parents = [0] * n
    for i, (kind, left, right) in enumerate(nodes):
        if kind == 0:
            if left != -1 or right != -1:
                return None
        elif kind == 1:
            if not i < left < n or right != -1:
                return None
            parents[left] += 1
        elif kind == 2:
            if not (i < left < n and i < right < n) or left == right:
                return None
            parents[left] += 1
            parents[right] += 1
        else:
            return None
    if parents[0] != 0 or any(parent_count != 1 for parent_count in parents[1:]):
        return None
    return n, costs, nodes


def _solve(parsed):
    n, costs, nodes = parsed
    infinity = 1 << 60
    best = [infinity] * n
    choice = [-1] * n
    for vertex in range(n - 1, -1, -1):
        kind, left, right = nodes[vertex]
        if kind == 0:
            best[vertex] = 0
            continue
        candidates = []
        if kind == 1 and costs[0] >= 0 and best[left] != infinity:
            candidates.append((costs[0] + best[left], 0))
        if kind == 2:
            if costs[1] >= 0 and best[left] != infinity and best[right] != infinity:
                candidates.append((costs[1] + best[left] + best[right], 1))
            if costs[2] >= 0 and nodes[left][0] == 1 and best[nodes[left][1]] != infinity and best[right] != infinity:
                candidates.append((costs[2] + best[nodes[left][1]] + best[right], 2))
            if costs[3] >= 0 and nodes[right][0] == 1 and best[left] != infinity and best[nodes[right][1]] != infinity:
                candidates.append((costs[3] + best[left] + best[nodes[right][1]], 3))
            if (costs[4] >= 0 and nodes[left][0] == 1 and nodes[right][0] == 1
                    and best[nodes[left][1]] != infinity and best[nodes[right][1]] != infinity):
                candidates.append((costs[4] + best[nodes[left][1]] + best[nodes[right][1]], 4))
        if candidates:
            best[vertex], choice[vertex] = min(candidates)
    if best[0] == infinity:
        return None
    mapping = [-1 if node[0] == 0 else -3 for node in nodes]

    def recover(vertex: int) -> None:
        pattern = choice[vertex]
        mapping[vertex] = pattern
        kind, left, right = nodes[vertex]
        if pattern == 0:
            recover(left)
        elif pattern == 1:
            recover(left); recover(right)
        elif pattern == 2:
            mapping[left] = -2
            recover(nodes[left][1]); recover(right)
        elif pattern == 3:
            mapping[right] = -2
            recover(left); recover(nodes[right][1])
        elif pattern == 4:
            mapping[left] = -2; mapping[right] = -2
            recover(nodes[left][1]); recover(nodes[right][1])

    if nodes[0][0] != 0:
        recover(0)
    return [best[0], *mapping]


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    result = _solve(parsed)
    if result is None:
        return -1, b""
    payload = b"".join(x.to_bytes(8, "little", signed=True) for x in result)
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < len(payload):
        return -2, b""
    return len(payload), payload
