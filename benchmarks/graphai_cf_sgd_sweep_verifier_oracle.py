"""Independent verifier oracle for the one-sweep GraphAIBench CF update."""
import math

MAX_INPUT_LENGTH = 95
MAX_OUTPUT_ELEMENTS = 32


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (not isinstance(values, (list, tuple)) or len(values) > MAX_INPUT_LENGTH
            or type(output_is_null) is not bool or type(input_is_null) is not bool
            or input_is_null and len(values) != 0
            or input_length is not None and input_length != len(values)
            or output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0)):
        return -1, []
    if input_is_null or len(values) < 6:
        return -1, []
    if any(type(x) not in (int, float) or not math.isfinite(float(x)) for x in values):
        return -1, []
    users, items, m, k = (int(values[i]) for i in range(4))
    if (any(float(values[i]) != (users, items, m, k)[i] for i in range(4))
            or not 1 <= users <= 7 or not 1 <= items <= 7 or users+items > 8
            or not 0 <= m <= 24 or not 1 <= k <= 4
            or not 0.0 <= float(values[4]) <= 1.0 or not 0.0 <= float(values[5]) <= 0.01
            or len(values) != 7+users+items+2*m+(users+items)*k):
        return -1, []
    n = users+items
    row_pos = 6
    col_pos = row_pos+n+1
    rating_pos = col_pos+m
    latent_pos = rating_pos+m
    raw_row = values[row_pos:col_pos]
    raw_col = values[col_pos:rating_pos]
    if any(float(v) != math.trunc(float(v)) for v in raw_row+raw_col):
        return -1, []
    row = [int(v) for v in raw_row]
    col = [int(v) for v in raw_col]
    if (row[0] != 0 or row[-1] != m or any(v < 0 or v > m for v in row)
            or any(row[i] > row[i+1] for i in range(n))
            or any(row[v] != row[v+1] for v in range(users, n))
            or any(v < users or v >= n for v in col)
            or any(not -4.0 <= float(v) <= 4.0 for v in values[rating_pos:latent_pos])
            or any(not -2.0 <= float(v) <= 2.0 for v in values[latent_pos:])):
        return -1, []
    count = n*k
    if output_is_null or output_capacity is not None and output_capacity < count:
        return -2, []
    latent = list(map(float, values[latent_pos:]))
    gradients = [0.0 for _ in range(count)]
    for u in range(users):
        edge = row[u]
        while edge < row[u+1]:
            v = col[edge]
            prediction = math.fsum(latent[u*k+j]*latent[v*k+j] for j in range(k))
            residual = float(values[rating_pos+edge])-prediction
            for j in range(k):
                gradients[u*k+j] = math.fsum((gradients[u*k+j], latent[v*k+j]*residual))
            edge += 1
    reg, rate = float(values[4]), float(values[5])
    output = []
    for vertex, factor_vector in enumerate(range(0, count, k)):
        for j in range(k):
            offset = factor_vector+j
            regularized_gradient = gradients[offset]-reg*latent[offset]
            output.append(latent[offset]+rate*regularized_gradient)
    return count, output
