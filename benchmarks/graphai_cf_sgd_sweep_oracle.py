"""Package oracle for one bounded GraphAIBench collaborative-filtering SGD sweep."""
import math

MAX_NODES, MAX_EDGES, MAX_FACTORS = 8, 24, 4
MAX_INPUT_LENGTH = 7 + MAX_NODES + 2 * MAX_EDGES + MAX_NODES * MAX_FACTORS
MAX_OUTPUT_ELEMENTS = MAX_NODES * MAX_FACTORS


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
    if input_is_null or len(values) < 6:
        return -1, []
    header = [float(x) for x in values[:4]]
    if any(x != math.trunc(x) for x in header):
        return -1, []
    users, items, edges, factors = map(int, header)
    n = users + items
    regularization, step = float(values[4]), float(values[5])
    if (not 1 <= users <= 7 or not 1 <= items <= 7 or n > MAX_NODES
            or not 0 <= edges <= MAX_EDGES or not 1 <= factors <= MAX_FACTORS
            or not 0.0 <= regularization <= 1.0 or not 0.0 <= step <= 0.01):
        return -1, []
    if len(values) != 7 + n + 2*edges + n*factors:
        return -1, []
    row_at = 6
    col_at = row_at + n + 1
    rating_at = col_at + edges
    latent_at = rating_at + edges
    raw_rows = values[row_at:col_at]
    raw_cols = values[col_at:rating_at]
    if any(float(x) != math.trunc(float(x)) for x in raw_rows+raw_cols):
        return -1, []
    rows = [int(x) for x in raw_rows]
    cols = [int(x) for x in raw_cols]
    if (rows[0] != 0 or rows[-1] != edges
            or any(x < 0 or x > edges for x in rows)
            or any(a > b for a, b in zip(rows, rows[1:]))
            or any(rows[u+1] != rows[u] for u in range(users, n))
            or any(x < users or x >= n for x in cols)
            or any(not -4.0 <= float(x) <= 4.0 for x in values[rating_at:latent_at])
            or any(not -2.0 <= float(x) <= 2.0 for x in values[latent_at:])):
        return -1, []
    required = n*factors
    if output_is_null or (output_capacity is not None and output_capacity < required):
        return -2, []
    latent = [float(x) for x in values[latent_at:]]
    error = [0.0] * required
    for user in range(users):
        for edge in range(rows[user], rows[user+1]):
            item = cols[edge]
            estimate = 0.0
            for factor in range(factors):
                estimate += latent[user*factors+factor] * latent[item*factors+factor]
            delta = float(values[rating_at+edge]) - estimate
            for factor in range(factors):
                error[user*factors+factor] += latent[item*factors+factor] * delta
    updated = [0.0] * required
    for vertex in range(n):
        for factor in range(factors):
            index = vertex*factors+factor
            updated[index] = latent[index] + step * (-regularization*latent[index] + error[index])
    return required, updated
