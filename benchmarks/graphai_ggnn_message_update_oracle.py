"""Direct clean-room oracle for the bounded GraphAIBench GGNN update."""

import math

MAX_NODES = 8
MAX_EDGES = 24
MAX_FEATURES = 4
MAX_VALID_INPUT_LENGTH = 452
MAX_PARSEABLE_INPUT_LENGTH = 453
MAX_OUTPUT_ELEMENTS = 32


def _numeric_values(values):
    if not isinstance(values, (list, tuple)):
        return None
    converted = []
    for value in values:
        if type(value) not in (int, float):
            return None
        try:
            number = float(value)
        except (OverflowError, ValueError):
            return None
        if not math.isfinite(number):
            return None
        converted.append(number)
    return converted


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    raw = _numeric_values(values)
    if (raw is None or len(raw) > MAX_PARSEABLE_INPUT_LENGTH
            or type(output_is_null) is not bool or type(input_is_null) is not bool
            or (input_is_null and len(raw) != 0)
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(raw)))
            or (output_capacity is not None
                and (type(output_capacity) is not int or output_capacity < 0))):
        return -1, []
    if input_is_null or len(raw) < 3:
        return -1, []
    nv, mv, dv = raw[:3]
    if (nv != math.trunc(nv) or mv != math.trunc(mv) or dv != math.trunc(dv)
            or not (1 <= nv <= MAX_NODES and 0 <= mv <= MAX_EDGES
                    and 1 <= dv <= MAX_FEATURES)):
        return -1, []
    n, m, d = int(nv), int(mv), int(dv)
    if len(raw) != 4 + n + m + n * d + 6 * n * n:
        return -1, []
    row_start = 3
    col_start = row_start + n + 1
    state_start = col_start + m
    wz_start = state_start + n * d
    wr_start = wz_start + n * n
    wc_start = wr_start + n * n
    uz_start = wc_start + n * n
    ur_start = uz_start + n * n
    uc_start = ur_start + n * n
    row_values = raw[row_start:col_start]
    col_values = raw[col_start:state_start]
    if (row_values[0] != 0 or row_values[-1] != m
            or any(value != math.trunc(value) or value < 0 or value > m
                   for value in row_values)
            or any(left > right for left, right in zip(row_values, row_values[1:]))
            or any(value != math.trunc(value) or value < 0 or value >= n
                   for value in col_values)):
        return -1, []
    if any(not -1.0 <= value <= 1.0 for value in raw[state_start:wz_start]):
        return -1, []
    if any(not -0.25 <= value <= 0.25 for value in raw[wz_start:]):
        return -1, []
    required = n * d
    if output_is_null or (output_capacity is not None and output_capacity < required):
        return -2, []

    rows = [int(value) for value in row_values]
    cols = [int(value) for value in col_values]
    aggregate = [0.0] * required
    update_gate = [0.0] * required
    reset_gate = [0.0] * required
    candidate = [0.0] * required
    output = [0.0] * required
    for vertex in range(n):
        for edge in range(rows[vertex], rows[vertex + 1]):
            neighbor = cols[edge]
            for feature in range(d):
                aggregate[vertex * d + feature] += raw[state_start + neighbor * d + feature]

    for vertex in range(n):
        for feature in range(d):
            wz = wr = uz = ur = 0.0
            for other in range(n):
                matrix_at = vertex * n + other
                feature_at = other * d + feature
                wz += raw[wz_start + matrix_at] * aggregate[feature_at]
                wr += raw[wr_start + matrix_at] * aggregate[feature_at]
                uz += raw[uz_start + matrix_at] * raw[state_start + feature_at]
                ur += raw[ur_start + matrix_at] * raw[state_start + feature_at]
            at = vertex * d + feature
            update_gate[at] = 1.0 / (1.0 + math.exp(-(wz + uz)))
            reset_gate[at] = 1.0 / (1.0 + math.exp(-(wr + ur)))

    for vertex in range(n):
        for feature in range(d):
            graph_part = state_part = 0.0
            for other in range(n):
                matrix_at = vertex * n + other
                feature_at = other * d + feature
                graph_part += raw[wc_start + matrix_at] * aggregate[feature_at]
                state_part += (raw[uc_start + matrix_at] * reset_gate[feature_at]
                               * raw[state_start + feature_at])
            at = vertex * d + feature
            candidate[at] = math.tanh(graph_part + state_part)
            output[at] = ((1.0 - update_gate[at]) * raw[state_start + at]
                          + update_gate[at] * candidate[at])
    return required, output
