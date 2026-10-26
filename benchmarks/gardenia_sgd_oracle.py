"""Independent bounded oracle for GARDENIA's sequential MF-SGD verifier."""
from __future__ import annotations

import math

MAX_USERS, MAX_ITEMS, MAX_EDGES, MAX_FACTORS = 7, 7, 24, 4
MAX_VERTICES = 8
MAX_INPUT_LENGTH = 92
MAX_OUTPUT_ELEMENTS = 32
REGULARIZATION = 0.001
STEP = 0.00000035
EPSILON = 0.1
MAX_ITERATIONS = 3


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (not isinstance(values, (list, tuple))
            or type(output_is_null) is not bool or type(input_is_null) is not bool
            or (input_is_null and values)
            or (input_length is not None and
                (type(input_length) is not int or input_length != len(values)))
            or (output_capacity is not None and
                (type(output_capacity) is not int or output_capacity < 0))):
        return -1, []
    if input_is_null or len(values) < 4 or len(values) > MAX_INPUT_LENGTH:
        return -1, []
    try:
        data = [float(value) for value in values]
    except (TypeError, ValueError, OverflowError):
        return -1, []
    if any(type(value) not in (int, float) or not math.isfinite(x)
           for value, x in zip(values, data)):
        return -1, []
    if any(data[i] != math.trunc(data[i]) for i in range(4)):
        return -1, []
    users, items, edges, factors = (int(data[i]) for i in range(4))
    n = users + items
    if (not 1 <= users <= MAX_USERS or not 1 <= items <= MAX_ITEMS
            or n > MAX_VERTICES or not 1 <= edges <= MAX_EDGES
            or not 1 <= factors <= MAX_FACTORS):
        return -1, []
    if len(data) != 5 + users + 2 * edges + n * factors:
        return -1, []
    row_at = 4
    col_at = row_at + users + 1
    rating_at = col_at + edges
    latent_at = rating_at + edges
    rows_raw = data[row_at:col_at]
    cols_raw = data[col_at:rating_at]
    if any(value != math.trunc(value) for value in rows_raw + cols_raw):
        return -1, []
    rows = [int(value) for value in rows_raw]
    cols = [int(value) for value in cols_raw]
    if (rows[0] != 0 or rows[-1] != edges
            or any(value < 0 or value > edges for value in rows)
            or any(a > b for a, b in zip(rows, rows[1:]))
            or any(value < 0 or value >= items for value in cols)
            or any(not -4.0 <= value <= 4.0 for value in data[rating_at:latent_at])
            or any(not 0.0 <= value <= 0.1 for value in data[latent_at:])):
        return -1, []
    required = n * factors
    if output_is_null or (output_capacity is not None and output_capacity < required):
        return -2, []

    latent = data[latent_at:]
    squared_errors = [0.0] * users
    for _ in range(MAX_ITERATIONS):
        squared_errors = [0.0] * users
        for user in range(users):
            for edge in range(rows[user], rows[user + 1]):
                item = users + cols[edge]
                estimate = 0.0
                for factor in range(factors):
                    estimate += latent[user * factors + factor] * latent[item * factors + factor]
                delta = data[rating_at + edge] - estimate
                squared_errors[user] += delta * delta
                for factor in range(factors):
                    u_at = user * factors + factor
                    i_at = item * factors + factor
                    p_u = latent[u_at]
                    p_i = latent[i_at]
                    latent[u_at] += STEP * (-REGULARIZATION * p_u + p_i * delta)
                    latent[i_at] += STEP * (-REGULARIZATION * p_i + p_u * delta)
        rmse = math.sqrt(sum(squared_errors) / edges)
        if rmse < EPSILON:
            break
    return required, latent
