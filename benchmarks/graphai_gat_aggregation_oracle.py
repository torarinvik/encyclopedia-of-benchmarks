"""Package oracle for bounded GraphAIBench GAT aggregation."""
import math

MAX_NODES, MAX_EDGES, MAX_FEATURES = 8, 24, 4
MAX_INPUT_LENGTH = 4 + MAX_NODES + MAX_EDGES + 2 * MAX_FEATURES + MAX_NODES * MAX_FEATURES
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
    if input_is_null or len(values) < 3:
        return -1, []
    header = [float(x) for x in values[:3]]
    if any(x != math.trunc(x) for x in header):
        return -1, []
    n, m, d = map(int, header)
    if not (1 <= n <= MAX_NODES and 0 <= m <= MAX_EDGES and 1 <= d <= MAX_FEATURES):
        return -1, []
    if len(values) != 4 + n + m + 2*d + n*d:
        return -1, []
    rp = 3
    ci = rp + n + 1
    al = ci + m
    ar = al + d
    xf = ar + d
    raw_rows = values[rp:ci]
    raw_cols = values[ci:al]
    if (any(float(x) != math.trunc(float(x)) for x in raw_rows + raw_cols)
            or any(not -8 <= float(x) <= 8 for x in values[al:])):
        return -1, []
    rows = [int(x) for x in raw_rows]
    cols = [int(x) for x in raw_cols]
    if (rows[0] != 0 or rows[-1] != m
            or any(x < 0 or x > m for x in rows)
            or any(a > b for a, b in zip(rows, rows[1:]))
            or any(x < 0 or x >= n for x in cols)):
        return -1, []
    if output_is_null or (output_capacity is not None and output_capacity < n*d):
        return -2, []
    left = [float(x) for x in values[al:ar]]
    right = [float(x) for x in values[ar:xf]]
    features = [float(x) for x in values[xf:]]
    scores = [0.0] * m
    weights = [0.0] * m
    result = [0.0] * (n*d)
    for src in range(n):
        begin, end = rows[src], rows[src+1]
        if begin == end:
            continue
        for edge in range(begin, end):
            dst = cols[edge]
            src_score = sum(left[k] * features[src*d+k] for k in range(d))
            dst_score = sum(right[k] * features[dst*d+k] for k in range(d))
            score = src_score + dst_score
            scores[edge] = score if score > 0.0 else 0.2 * score
        maximum = max(scores[begin:end])
        exponentials = [math.exp(scores[e] - maximum) for e in range(begin, end)]
        denominator = sum(exponentials)
        for offset, edge in enumerate(range(begin, end)):
            weights[edge] = exponentials[offset] / denominator
        for edge in range(begin, end):
            dst = cols[edge]
            for k in range(d):
                result[src*d+k] += weights[edge] * features[dst*d+k]
    return len(result), result
