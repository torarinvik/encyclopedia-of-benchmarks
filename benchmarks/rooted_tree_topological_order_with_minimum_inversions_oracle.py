"""Ratio-contraction reference for the bounded rooted-order profile."""

from __future__ import annotations

import struct

MAX_N = 12
MAX_WEIGHT = 1_000_000
MAX_VALID_INPUT_LENGTH = 3 * MAX_N
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (MAX_N + 1)


def _parse(values, input_is_null, input_length):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 0
            or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values) or len(values) < 3):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != 3 * n:
        return None
    parents = [-1] + list(values[1:n])
    if any(not 0 <= parents[vertex] < vertex for vertex in range(1, n)):
        return None
    c_values = list(values[n:2 * n])
    d_values = list(values[2 * n:3 * n])
    if any(not 0 <= value <= MAX_WEIGHT for value in c_values + d_values):
        return None
    if sum(c_values) > MAX_WEIGHT or sum(d_values) > MAX_WEIGHT:
        return None
    return n, parents, c_values, d_values


def _ratio_compare(left_c, left_d, right_c, right_d):
    left_zero = left_c == 0 and left_d == 0
    right_zero = right_c == 0 and right_d == 0
    if left_zero != right_zero:
        return -1 if left_zero else 1
    lhs = left_c * right_d
    rhs = left_d * right_c
    return (lhs > rhs) - (lhs < rhs)


def _contract_order(n, parents, c_values, d_values):
    aggregate_c = c_values.copy()
    aggregate_d = d_values.copy()
    dsu_parent = list(range(n))
    component_label = list(range(n))
    active = [vertex != 0 for vertex in range(n)]
    link = list(range(n))

    def find(vertex):
        root = vertex
        while dsu_parent[root] != root:
            root = dsu_parent[root]
        while dsu_parent[vertex] != vertex:
            next_vertex = dsu_parent[vertex]
            dsu_parent[vertex] = root
            vertex = next_vertex
        return root

    for _ in range(n - 1):
        selected = None
        for candidate in range(1, n):
            if not active[candidate]:
                continue
            if selected is None:
                selected = candidate
                continue
            comparison = _ratio_compare(
                aggregate_c[candidate], aggregate_d[candidate],
                aggregate_c[selected], aggregate_d[selected],
            )
            if comparison > 0 or (comparison == 0 and candidate > selected):
                selected = candidate
        if selected is None:
            return None

        parent_component = find(parents[selected])
        target = component_label[parent_component]
        child_component = find(selected)
        if child_component == parent_component:
            return None
        aggregate_c[target] += aggregate_c[selected]
        aggregate_d[target] += aggregate_d[selected]
        dsu_parent[child_component] = parent_component
        component_label[parent_component] = target
        active[selected] = False
        if target != 0:
            active[target] = True
        link[selected], link[target] = link[target], link[selected]

    traversal = []
    vertex = link[0]
    while len(traversal) < n:
        traversal.append(vertex)
        if vertex == 0:
            break
        vertex = link[vertex]
    if len(traversal) != n or traversal[-1] != 0:
        return None
    return list(reversed(traversal))


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Return the contraction order and objective as little-endian i64 words."""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    n, parents, c_values, d_values = parsed
    order = _contract_order(n, parents, c_values, d_values)
    if order is None:
        return -1, b""
    objective = 0
    prefix_d = 0
    for vertex in order:
        objective += c_values[vertex] * prefix_d
        prefix_d += d_values[vertex]
    words = [objective, *order]
    payload = b"".join(struct.pack("<q", word) for word in words)

    capacity = MAX_OUTPUT_BYTES if output_capacity is None else output_capacity
    if (type(output_is_null) is not bool or type(capacity) is not int
            or capacity < 0):
        return -2, b""
    if output_is_null or capacity < len(payload):
        return -2, b""
    return len(payload), payload
