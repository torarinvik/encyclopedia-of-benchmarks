"""Independent ABI oracle for a bounded GraphAIBench GCN aggregation profile."""

import math

MAX_NODES = 8
MAX_EDGES = 24
MAX_FEATURES = 4
MAX_INPUT_LENGTH = 4 + 3 * MAX_NODES + MAX_EDGES + MAX_NODES * MAX_FEATURES
MAX_OUTPUT_ELEMENTS = MAX_NODES * MAX_FEATURES
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Return (result, output), summing weighted outgoing-neighbor features."""
    if (not isinstance(values, (list, tuple)) or len(values) > MAX_INPUT_LENGTH
            or type(output_is_null) is not bool or type(input_is_null) is not bool
            or (input_is_null and values)
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or (output_capacity is not None
                and (type(output_capacity) is not int or output_capacity < 0))):
        return INVALID_RESULT, []
    if input_is_null or len(values) < 4:
        return INVALID_RESULT, []
    if any(type(value) not in (int, float) or not math.isfinite(float(value))
           for value in values):
        return INVALID_RESULT, []

    n_value, m_value, d_value = (float(value) for value in values[:3])
    if any(value != math.trunc(value) for value in (n_value, m_value, d_value)):
        return INVALID_RESULT, []
    n, m, d = int(n_value), int(m_value), int(d_value)
    if not 1 <= n <= MAX_NODES or not 0 <= m <= MAX_EDGES or not 1 <= d <= MAX_FEATURES:
        return INVALID_RESULT, []
    if len(values) != 4 + 3 * n + m + n * d:
        return INVALID_RESULT, []

    offsets_at = 3
    edges_at = offsets_at + n + 1
    source_norm_at = edges_at + m
    destination_norm_at = source_norm_at + n
    features_at = destination_norm_at + n
    if any(float(value) != math.trunc(float(value)) or not 0 <= value <= m
           for value in values[offsets_at:edges_at]):
        return INVALID_RESULT, []
    offsets = [int(value) for value in values[offsets_at:edges_at]]
    if offsets[0] != 0 or offsets[-1] != m or any(a > b for a, b in zip(offsets, offsets[1:])):
        return INVALID_RESULT, []
    if any(float(value) != math.trunc(float(value)) or not 0 <= value < n
           for value in values[edges_at:source_norm_at]):
        return INVALID_RESULT, []
    if any(not -4 <= float(value) <= 4
           for value in values[source_norm_at:destination_norm_at]):
        return INVALID_RESULT, []
    if any(not -4 <= float(value) <= 4
           for value in values[destination_norm_at:features_at]):
        return INVALID_RESULT, []
    if any(not -8 <= float(value) <= 8 for value in values[features_at:]):
        return INVALID_RESULT, []
    if output_is_null or output_capacity is not None and output_capacity < n * d:
        return OUTPUT_ERROR, []

    edges = [int(value) for value in values[edges_at:source_norm_at]]
    source_norm = [float(value) for value in values[source_norm_at:destination_norm_at]]
    destination_norm = [float(value) for value in values[destination_norm_at:features_at]]
    features = [float(value) for value in values[features_at:]]
    result = [0.0] * (n * d)
    # The order matches the source's CSR row order and feature-vector accumulation.
    for src in range(n):
        for edge in range(offsets[src], offsets[src + 1]):
            dst = edges[edge]
            weight = source_norm[src] * destination_norm[dst]
            for feature in range(d):
                index = src * d + feature
                result[index] += weight * features[dst * d + feature]
    return len(result), result


