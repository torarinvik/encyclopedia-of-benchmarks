"""Package oracle for a bounded GraphAIBench GraphSAGE mean aggregator."""
import math

MAX_NODES, MAX_EDGES, MAX_FEATURES = 8, 24, 4
MAX_INPUT_LENGTH = 4 + MAX_NODES + MAX_EDGES + MAX_NODES * MAX_FEATURES
MAX_OUTPUT_ELEMENTS = MAX_NODES * MAX_FEATURES


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (not isinstance(values, (list, tuple)) or len(values) > MAX_INPUT_LENGTH
            or type(output_is_null) is not bool or type(input_is_null) is not bool
            or (input_is_null and values)
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or (output_capacity is not None
                and (type(output_capacity) is not int or output_capacity < 0))
            or any(type(x) not in (int, float) or not math.isfinite(float(x)) for x in values)):
        return -1, []
    if input_is_null or len(values) < 4:
        return -1, []
    header = [float(x) for x in values[:3]]
    if any(x != math.trunc(x) for x in header):
        return -1, []
    n, m, d = map(int, header)
    if not 1 <= n <= MAX_NODES or not 0 <= m <= MAX_EDGES or not 1 <= d <= MAX_FEATURES:
        return -1, []
    if len(values) != 4 + n + m + n*d:
        return -1, []
    row_start = 3
    edge_start = row_start + n + 1
    feature_start = edge_start + m
    raw_rows = values[row_start:edge_start]
    raw_edges = values[edge_start:feature_start]
    if (any(float(x) != math.trunc(float(x)) for x in raw_rows + raw_edges)
            or any(not -8 <= float(x) <= 8 for x in values[feature_start:])):
        return -1, []
    rowptr = [int(x) for x in raw_rows]
    colind = [int(x) for x in raw_edges]
    if (rowptr[0] != 0 or rowptr[-1] != m
            or any(x < 0 or x > m for x in rowptr)
            or any(a > b for a, b in zip(rowptr, rowptr[1:]))
            or any(x < 0 or x >= n for x in colind)):
        return -1, []
    if output_is_null or output_capacity is not None and output_capacity < n*d:
        return -2, []
    features = [float(x) for x in values[feature_start:]]
    output = [0.0] * (n*d)
    for src in range(n):
        degree = rowptr[src+1] - rowptr[src]
        if degree:
            mean_scale = 1.0 / degree
            for edge in range(rowptr[src], rowptr[src+1]):
                dst = colind[edge]
                for k in range(d):
                    output[src*d+k] += mean_scale * features[dst*d+k]
    return len(output), output
