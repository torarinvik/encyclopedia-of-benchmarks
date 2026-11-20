"""Multi-source BFS on the graph x visited-subset product state space."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 10
MAX_M = MAX_N * (MAX_N - 1) // 2
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_M
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> tuple[int, list[int]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    n, m = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= m <= MAX_M:
        return None
    if m > n * (n - 1) // 2 or len(values) != 2 + 2 * m:
        return None
    adjacency = [0] * n
    seen: set[tuple[int, int]] = set()
    cursor = 2
    for _ in range(m):
        u, v = values[cursor:cursor + 2]
        cursor += 2
        if not 0 <= u < n or not 0 <= v < n or u == v:
            return None
        edge = (min(u, v), max(u, v))
        if edge in seen:
            return None
        seen.add(edge)
        adjacency[u] |= 1 << v
        adjacency[v] |= 1 << u

    reached = 1
    frontier = 1
    while frontier:
        bit = frontier & -frontier
        frontier ^= bit
        vertex = bit.bit_length() - 1
        additions = adjacency[vertex] & ~reached
        reached |= additions
        frontier |= additions
    if reached != (1 << n) - 1:
        return None
    return n, adjacency


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return INVALID_RESULT
    n, adjacency = decoded
    full = (1 << n) - 1
    state_count = (1 << n) * n
    distance = [-1] * state_count
    queue = [0] * state_count
    tail = 0
    for start in range(n):
        mask = 1 << start
        state = mask * n + start
        distance[state] = 0
        queue[tail] = state
        tail += 1

    head = 0
    while head < tail:
        state = queue[head]
        head += 1
        mask, vertex = divmod(state, n)
        steps = distance[state]
        if mask == full:
            return steps
        neighbors = adjacency[vertex]
        while neighbors:
            bit = neighbors & -neighbors
            neighbors ^= bit
            next_vertex = bit.bit_length() - 1
            next_mask = mask | bit
            next_state = next_mask * n + next_vertex
            if distance[next_state] < 0:
                distance[next_state] = steps + 1
                queue[tail] = next_state
                tail += 1
    return INVALID_RESULT
