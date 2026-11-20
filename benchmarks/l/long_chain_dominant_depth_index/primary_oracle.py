"""Long-chain DP reference for the bounded dominant-depth profile."""

from __future__ import annotations

MAX_N = 64
MAX_PARSEABLE_INPUT_LENGTH = 65
MAX_OUTPUT_BYTES = 8 * MAX_N
MAX_WORKSPACE_BYTES = 8192


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
    if not values or not 1 <= values[0] <= MAX_N or len(values) != values[0]:
        return None
    n = values[0]
    parent = [-1] * n
    children = [[] for _ in range(n)]
    for vertex in range(1, n):
        p = values[vertex]
        if not 0 <= p < vertex:
            return None
        parent[vertex] = p
        children[p].append(vertex)
    return n, parent, children


def _long_chain_indices(n: int, parent: list[int], children: list[list[int]]) -> list[int]:
    height = [1] * n
    heavy = [-1] * n
    for vertex in range(n - 1, -1, -1):
        best_height = 0
        for child in children[vertex]:
            if (height[child] > best_height
                    or height[child] == best_height and child < heavy[vertex]):
                best_height = height[child]
                heavy[vertex] = child
        height[vertex] = best_height + 1

    base = [-1] * n
    pool_size = 0
    for vertex in range(n):
        if vertex == 0 or heavy[parent[vertex]] != vertex:
            current = vertex
            while current >= 0:
                base[current] = pool_size
                pool_size += 1
                current = heavy[current]

    counts = [0] * n
    dominant_depth = [0] * n
    dominant_count = [0] * n
    for vertex in range(n - 1, -1, -1):
        counts[base[vertex]] = 1
        best_depth = 0
        best_count = 1
        heavy_child = heavy[vertex]
        if heavy_child >= 0:
            best_depth = dominant_depth[heavy_child] + 1
            best_count = counts[base[vertex] + best_depth]
        for child in children[vertex]:
            if child == heavy_child:
                continue
            for child_depth in range(height[child]):
                depth = child_depth + 1
                count = counts[base[vertex] + depth] + counts[base[child] + child_depth]
                counts[base[vertex] + depth] = count
                if count > best_count or count == best_count and depth < best_depth:
                    best_depth = depth
                    best_count = count
        dominant_depth[vertex] = best_depth
        dominant_count[vertex] = best_count
    return dominant_depth


def expected_output(values, input_is_null: bool = False,
                    input_length: int | None = None,
                    output_capacity: int = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False) -> tuple[int, bytes]:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1, b""
    n, parent, children = decoded
    required = 8 * n
    if type(output_is_null) is not bool or type(output_capacity) is not int:
        return -2, b""
    if output_is_null or output_capacity < required:
        return -2, b""
    result = _long_chain_indices(n, parent, children)
    return required, b"".join(value.to_bytes(8, "little", signed=True) for value in result)
