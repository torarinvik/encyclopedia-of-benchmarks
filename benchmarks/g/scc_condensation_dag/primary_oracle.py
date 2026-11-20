"""Kosaraju SCC decomposition followed by quotient-DAG construction."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_VERTICES = 8
MAX_EDGES = 28
MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 1 + 2 * MAX_VERTICES


def _decode(values, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) < 2:
        return None
    n, m = values[:2]
    if not 0 <= n <= MAX_VERTICES or not 0 <= m <= MAX_EDGES or len(values) != 2 + 2 * m:
        return None
    adjacency = [set() for _ in range(n)]
    reverse = [set() for _ in range(n)]
    edges = []
    for i in range(m):
        source, target = values[2 + 2 * i: 4 + 2 * i]
        if not 0 <= source < n or not 0 <= target < n:
            return None
        adjacency[source].add(target)
        reverse[target].add(source)
        edges.append((source, target))
    return n, adjacency, reverse, edges


def expected_output(values, output_capacity=None, input_is_null=False,
                    output_is_null=False, input_length=None):
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1, b""
    if type(output_is_null) is not bool:
        return -1, b""
    n, adjacency, reverse, edges = decoded

    visited = [False] * n
    finish_order = []
    for start in range(n):
        if visited[start]:
            continue
        visited[start] = True
        stack = [[start, iter(sorted(adjacency[start]))]]
        while stack:
            vertex, neighbors = stack[-1]
            following = next(neighbors, None)
            if following is None:
                finish_order.append(vertex)
                stack.pop()
            elif not visited[following]:
                visited[following] = True
                stack.append([following, iter(sorted(adjacency[following]))])

    raw_component = [-1] * n
    component_count = 0
    visited = [False] * n
    for start in reversed(finish_order):
        if visited[start]:
            continue
        visited[start] = True
        raw_component[start] = component_count
        stack = [start]
        while stack:
            vertex = stack.pop()
            for following in sorted(reverse[vertex], reverse=True):
                if not visited[following]:
                    visited[following] = True
                    raw_component[following] = component_count
                    stack.append(following)
        component_count += 1

    minima = [n] * component_count
    for vertex, component in enumerate(raw_component):
        minima[component] = min(minima[component], vertex)
    raw_order = sorted(range(component_count), key=lambda component: minima[component])
    canonical = [0] * component_count
    for component_id, raw_id in enumerate(raw_order):
        canonical[raw_id] = component_id
    labels = [canonical[component] for component in raw_component]

    row_masks = [0] * component_count
    for source, target in edges:
        left, right = labels[source], labels[target]
        if left != right:
            row_masks[left] |= 1 << right
    output = bytes([component_count, *labels, *row_masks])
    if (type(output_is_null) is not bool or output_is_null
            or (output_capacity is not None
                and (type(output_capacity) is not int or output_capacity < len(output)))):
        return -2, b""
    return len(output), output


def expected_result(values, output_capacity=None, input_is_null=False,
                    output_is_null=False, input_length=None):
    return expected_output(values, output_capacity, input_is_null,
                          output_is_null, input_length)[0]
