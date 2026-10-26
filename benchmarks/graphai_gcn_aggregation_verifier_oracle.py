"""Independent reference for GraphAIBench's bounded GCN aggregation profile."""

import math

N_LIMIT = 8
M_LIMIT = 24
D_LIMIT = 4
INPUT_LIMIT = 84
OUTPUT_LIMIT = 32


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (not isinstance(values, (list, tuple)) or len(values) > INPUT_LIMIT
            or type(output_is_null) is not bool or type(input_is_null) is not bool
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or (input_is_null and (values or input_length not in (None, 0)))
            or (capacity is not None and (type(capacity) is not int or capacity < 0))
            or any(type(x) not in (int, float) or not math.isfinite(float(x)) for x in values)):
        return -1, []
    if input_is_null or len(values) < 4:
        return -1, []
    header = [float(x) for x in values[:3]]
    if any(x != math.trunc(x) for x in header):
        return -1, []
    n, m, d = map(int, header)
    if not (1 <= n <= N_LIMIT and 0 <= m <= M_LIMIT and 1 <= d <= D_LIMIT):
        return -1, []
    if len(values) != 4 + 3*n + m + n*d:
        return -1, []
    offsets_start = 3
    edge_start = offsets_start + n + 1
    left_start = edge_start + m
    right_start = left_start + n
    data_start = right_start + n
    offsets_raw = values[offsets_start:edge_start]
    edges_raw = values[edge_start:left_start]
    if any(float(x) != math.trunc(float(x)) for x in offsets_raw + edges_raw):
        return -1, []
    offsets = [int(x) for x in offsets_raw]
    edges = [int(x) for x in edges_raw]
    if (offsets[0] != 0 or offsets[-1] != m
            or any(x < 0 or x > m for x in offsets)
            or any(left > right for left, right in zip(offsets, offsets[1:]))
            or any(x < 0 or x >= n for x in edges)):
        return -1, []
    scale_left = [float(x) for x in values[left_start:right_start]]
    scale_right = [float(x) for x in values[right_start:data_start]]
    node_features = [float(x) for x in values[data_start:]]
    if (any(not -4 <= x <= 4 for x in scale_left + scale_right)
            or any(not -8 <= x <= 8 for x in node_features)):
        return -1, []
    if output_is_null or capacity is not None and capacity < n*d:
        return -2, []
    output = []
    # Feature-wise reductions independently traverse the CSR rows.
    for vertex in range(n):
        for feature in range(d):
            total = 0.0
            for edge_position in range(offsets[vertex], offsets[vertex + 1]):
                neighbor = edges[edge_position]
                total += (scale_left[vertex] * scale_right[neighbor]
                          * node_features[neighbor*d + feature])
            output.append(total)
    return len(output), output
