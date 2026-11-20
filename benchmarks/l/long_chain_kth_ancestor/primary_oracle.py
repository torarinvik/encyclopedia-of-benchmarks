"""Binary-lift plus long-chain lookup reference for bounded tree queries."""

from __future__ import annotations

MAX_N = 64
MAX_Q = 32
MAX_VALID_INPUT_LENGTH = 129
MAX_PARSEABLE_INPUT_LENGTH = 130
MAX_OUTPUT_BYTES = 8 * MAX_Q
MAX_WORKSPACE_BYTES = 16384
LOG_LEVELS = 6


def _decode(values, input_is_null: bool, input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) < 2:
        return None
    n, q = values[0], values[1]
    if not 1 <= n <= MAX_N or not 1 <= q <= MAX_Q:
        return None
    if len(values) != n + 1 + 2 * q:
        return None
    parents = [-1] * n
    for vertex in range(1, n):
        parent = values[1 + vertex]
        if not 0 <= parent < vertex:
            return None
        parents[vertex] = parent
    queries: list[tuple[int, int]] = []
    query_start = n + 1
    for query in range(q):
        vertex, distance = values[query_start + 2 * query:query_start + 2 * query + 2]
        if not 0 <= vertex < n or not 0 <= distance < MAX_N:
            return None
        queries.append((vertex, distance))
    return n, parents, queries


def _long_chain_answer(n: int, parent: list[int], queries: list[tuple[int, int]]) -> list[int]:
    depth = [0] * n
    height = [1] * n
    heavy = [-1] * n
    for vertex in range(1, n):
        depth[vertex] = depth[parent[vertex]] + 1
    for vertex in range(n - 1, 0, -1):
        p = parent[vertex]
        old = heavy[p]
        if (old < 0 or height[vertex] > height[old]
                or height[vertex] == height[old] and vertex < old):
            heavy[p] = vertex
        height[p] = max(height[p], height[vertex] + 1)

    chain_head = [-1] * n
    chain_position = [0] * n
    chain_base = [-1] * n
    chain_nodes = [0] * n
    head_ancestors = [-1] * n
    pool = 0
    for vertex in range(n):
        if vertex == 0 or heavy[parent[vertex]] != vertex:
            chain_base[vertex] = pool
            current = vertex
            position = 0
            while current >= 0:
                chain_head[current] = vertex
                chain_position[current] = position
                chain_nodes[pool + position] = current
                current = heavy[current]
                position += 1
            current = parent[vertex]
            for offset in range(position):
                head_ancestors[pool + offset] = current
                current = parent[current] if current >= 0 else -1
            pool += position

    up = [[-1] * n for _ in range(LOG_LEVELS)]
    up[0][:] = parent
    for level in range(1, LOG_LEVELS):
        for vertex in range(n):
            halfway = up[level - 1][vertex]
            up[level][vertex] = up[level - 1][halfway] if halfway >= 0 else -1

    answers: list[int] = []
    for vertex, distance in queries:
        if distance > depth[vertex]:
            answers.append(-1)
            continue
        if distance == 0:
            answers.append(vertex)
            continue
        level = distance.bit_length() - 1
        jumped = up[level][vertex]
        remaining = distance - (1 << level)
        head = chain_head[jumped]
        position = chain_position[jumped]
        if remaining <= position:
            answers.append(chain_nodes[chain_base[head] + position - remaining])
        else:
            steps_above_head = remaining - position
            if steps_above_head > height[head]:
                answers.append(-1)
            else:
                answers.append(head_ancestors[chain_base[head] + steps_above_head - 1])
    return answers


def expected_output(values, input_is_null: bool = False,
                    input_length: int | None = None,
                    output_capacity: int = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False) -> tuple[int, bytes]:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1, b""
    n, parent, queries = decoded
    del n
    required = 8 * len(queries)
    if type(output_is_null) is not bool or type(output_capacity) is not int:
        return -2, b""
    if output_is_null or output_capacity < required:
        return -2, b""
    answers = _long_chain_answer(len(parent), parent, queries)
    return required, b"".join(answer.to_bytes(8, "little", signed=True) for answer in answers)
