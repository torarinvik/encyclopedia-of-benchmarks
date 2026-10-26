"""Independent checker oracle for bounded GraphAIBench GAT aggregation."""
import math

MAX_INPUT_LENGTH = 76
MAX_OUTPUT_ELEMENTS = 32


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (not isinstance(values, (list, tuple)) or len(values) > MAX_INPUT_LENGTH
            or type(output_is_null) is not bool or type(input_is_null) is not bool
            or (input_is_null and len(values) != 0)
            or (input_length is not None and input_length != len(values))
            or (output_capacity is not None
                and (type(output_capacity) is not int or output_capacity < 0)):
        return -1, []
    if input_is_null or len(values) < 3:
        return -1, []
    if any(type(value) not in (int, float) or not math.isfinite(float(value)) for value in values):
        return -1, []
    n, m, d = (int(values[i]) for i in range(3))
    if (any(float(values[i]) != (n, m, d)[i] for i in range(3))
            or not 1 <= n <= 8 or not 0 <= m <= 24 or not 1 <= d <= 4
            or len(values) != 4+n+m+2*d+n*d):
        return -1, []
    row_at = 3
    edge_at = row_at+n+1
    left_at = edge_at+m
    right_at = left_at+d
    feature_at = right_at+d
    row_raw = values[row_at:edge_at]
    edge_raw = values[edge_at:left_at]
    if any(float(x) != math.trunc(float(x)) for x in row_raw+edge_raw):
        return -1, []
    if any(not -8 <= float(x) <= 8 for x in values[left_at:]):
        return -1, []
    row = [int(x) for x in row_raw]
    col = [int(x) for x in edge_raw]
    if (row[0] != 0 or row[-1] != m or any(x < 0 or x > m for x in row)
            or any(row[i] > row[i+1] for i in range(n))
            or any(x < 0 or x >= n for x in col)):
        return -1, []
    required = n*d
    if output_is_null or output_capacity is not None and output_capacity < required:
        return -2, []
    a = [float(x) for x in values[left_at:right_at]]
    b = [float(x) for x in values[right_at:feature_at]]
    x = [float(v) for v in values[feature_at:]]
    answer = [0.0] * required
    for u in range(n):
        first, stop = row[u], row[u+1]
        if first == stop:
            continue
        raw_scores = []
        for e in range(first, stop):
            v = col[e]
            score = math.fsum(a[k]*x[u*d+k] + b[k]*x[v*d+k] for k in range(d))
            raw_scores.append(score if score > 0.0 else score*0.2)
        score_ceiling = max(raw_scores)
        exp_values = [math.exp(score-score_ceiling) for score in raw_scores]
        total = math.fsum(exp_values)
        for local, e in enumerate(range(first, stop)):
            scale = exp_values[local] / total
            v = col[e]
            for k in range(d):
                answer[u*d+k] = math.fsum((answer[u*d+k], scale*x[v*d+k]))
    return required, answer
