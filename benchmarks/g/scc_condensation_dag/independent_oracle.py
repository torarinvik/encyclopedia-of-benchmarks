"""Mutual-reachability partition plus direct quotient construction."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_VERTICES = 8
MAX_EDGES = 28
MAX_INPUT_LENGTH = 58
MAX_PARSEABLE_INPUT_LENGTH = 59
MAX_OUTPUT_BYTES = 17


def expected_output(values, output_capacity=None, input_is_null=False,
                    output_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return -1, b""
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return -1, b""
    if len(values) < 2:
        return -1, b""
    n, m = values[:2]
    if not 0 <= n <= MAX_VERTICES or not 0 <= m <= MAX_EDGES or len(values) != 2 + 2 * m:
        return -1, b""
    reach = [[False] * n for _ in range(n)]
    for vertex in range(n):
        reach[vertex][vertex] = True
    edges = []
    for i in range(m):
        source, target = values[2 + 2 * i:4 + 2 * i]
        if not 0 <= source < n or not 0 <= target < n:
            return -1, b""
        reach[source][target] = True
        edges.append((source, target))
    for middle in range(n):
        for source in range(n):
            if reach[source][middle]:
                for target in range(n):
                    reach[source][target] = reach[source][target] or reach[middle][target]

    labels = [-1] * n
    component_count = 0
    for representative in range(n):
        if labels[representative] >= 0:
            continue
        labels[representative] = component_count
        for vertex in range(representative + 1, n):
            if (labels[vertex] < 0 and reach[representative][vertex]
                    and reach[vertex][representative]):
                labels[vertex] = component_count
        component_count += 1
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
