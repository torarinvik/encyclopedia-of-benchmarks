"""Independent direct-neighbor reference for bounded GraphSAGE aggregation."""
import math


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (not isinstance(values, (list, tuple)) or len(values) > 68
            or type(output_is_null) is not bool or type(input_is_null) is not bool
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or (input_is_null and (values or input_length not in (None, 0)))
            or (capacity is not None and (type(capacity) is not int or capacity < 0))
            or any(type(v) not in (int, float) or not math.isfinite(float(v)) for v in values)):
        return -1, []
    if input_is_null or len(values) < 4:
        return -1, []
    dims = tuple(float(v) for v in values[:3])
    if any(x != math.trunc(x) for x in dims):
        return -1, []
    n, m, d = (int(x) for x in dims)
    if not (1 <= n <= 8 and 0 <= m <= 24 and 1 <= d <= 4):
        return -1, []
    if len(values) != 4 + n + m + n*d:
        return -1, []
    ptr_base = 3
    col_base = ptr_base + n + 1
    feat_base = col_base + m
    rowptr_values = values[ptr_base:col_base]
    col_values = values[col_base:feat_base]
    if any(float(x) != math.trunc(float(x)) for x in rowptr_values + col_values):
        return -1, []
    rowptr = [int(x) for x in rowptr_values]
    colind = [int(x) for x in col_values]
    if (rowptr[0] != 0 or rowptr[-1] != m or any(x < 0 or x > m for x in rowptr)
            or any(rowptr[i] > rowptr[i+1] for i in range(n))
            or any(x < 0 or x >= n for x in colind)
            or any(not -8 <= float(x) <= 8 for x in values[feat_base:])):
        return -1, []
    if output_is_null or capacity is not None and capacity < n*d:
        return -2, []
    # Form a neighbor list and calculate each component with an explicit mean.
    features = [float(x) for x in values[feat_base:]]
    answer = []
    for row in range(n):
        neighbors = [colind[pos] for pos in range(rowptr[row], rowptr[row+1])]
        if not neighbors:
            answer.extend([0.0] * d)
        else:
            for feature in range(d):
                answer.append(sum(features[v*d+feature] for v in neighbors) / len(neighbors))
    return len(answer), answer
