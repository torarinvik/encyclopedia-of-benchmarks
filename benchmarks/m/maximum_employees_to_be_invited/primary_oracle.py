"""Indegree-peeling oracle for the bounded favorite-seating profile."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 8
MAX_VALID_INPUT_LENGTH = MAX_N + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1


def _decode(values: Sequence[int] | None, input_length: int | None) -> list[int] | None:
    if not isinstance(values, (list, tuple)):
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) < 3 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    n = values[0]
    if not 2 <= n <= MAX_N or len(values) != n + 1:
        return None
    favorite = list(values[1:])
    if any(not 0 <= favorite[i] < n or favorite[i] == i for i in range(n)):
        return None
    return favorite


def expected_result(values: Sequence[int] | None, input_length: int | None = None) -> int:
    favorite = _decode(values, input_length)
    if favorite is None:
        return INVALID_RESULT

    n = len(favorite)
    indegree = [0] * n
    longest_chain = [1] * n
    queue = [0] * n
    head = 0
    tail = 0
    for target in favorite:
        indegree[target] += 1
    for node, degree in enumerate(indegree):
        if degree == 0:
            queue[tail] = node
            tail += 1

    while head < tail:
        node = queue[head]
        head += 1
        target = favorite[node]
        longest_chain[target] = max(longest_chain[target], longest_chain[node] + 1)
        indegree[target] -= 1
        if indegree[target] == 0:
            queue[tail] = target
            tail += 1

    visited = [False] * n
    paired_components = 0
    largest_long_cycle = 0
    for start in range(n):
        if indegree[start] == 0 or visited[start]:
            continue
        cycle: list[int] = []
        node = start
        while not visited[node]:
            visited[node] = True
            cycle.append(node)
            node = favorite[node]
        if len(cycle) == 2:
            paired_components += longest_chain[cycle[0]] + longest_chain[cycle[1]]
        elif len(cycle) >= 3:
            largest_long_cycle = max(largest_long_cycle, len(cycle))
    return max(paired_components, largest_long_cycle)


def expected_output(values: Sequence[int] | None, input_length: int | None = None) -> int:
    return expected_result(values, input_length)
