"""Package oracle for a bounded deterministic GraphAIBench frontier sampler."""
import math

FANOUTS = (3, 2, 2)
MAX_NODES, MAX_EDGES, MAX_ROOTS = 8, 24, 4
CHOICES_PER_ROOT = sum((3, 6, 12))
MAX_INPUT_LENGTH = 4 + MAX_NODES + MAX_EDGES + 22 * MAX_ROOTS
MAX_OUTPUT_ELEMENTS = 22 * MAX_ROOTS


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
    n, m, root_count = map(int, header)
    if not (1 <= n <= MAX_NODES and 0 <= m <= MAX_EDGES and 1 <= root_count <= MAX_ROOTS):
        return -1, []
    if len(values) != 4 + n + m + 22 * root_count:
        return -1, []
    root_at = 3
    row_at = root_at + root_count
    col_at = row_at + n + 1
    choice_at = col_at + m
    raw_roots = values[root_at:row_at]
    raw_rows = values[row_at:col_at]
    raw_cols = values[col_at:choice_at]
    raw_choices = values[choice_at:]
    if any(float(x) != math.trunc(float(x)) for x in raw_roots + raw_rows + raw_cols + raw_choices):
        return -1, []
    roots = [int(x) for x in raw_roots]
    rows = [int(x) for x in raw_rows]
    cols = [int(x) for x in raw_cols]
    choices = [int(x) for x in raw_choices]
    if (rows[0] != 0 or rows[-1] != m
            or any(x < 0 or x > m for x in rows)
            or any(a > b for a, b in zip(rows, rows[1:]))
            or any(x < 0 or x >= n for x in roots)
            or any(x < 0 or x >= n for x in cols)):
        return -1, []
    required = 22 * root_count
    if output_is_null or (output_capacity is not None and output_capacity < required):
        return -2, []
    frontiers = [roots]
    choice_index = 0
    for fanout in FANOUTS:
        current = frontiers[-1]
        following = []
        for parent in current:
            begin, end = rows[parent], rows[parent+1]
            degree = end - begin
            if degree == 0:
                return -1, []
            for _ in range(fanout):
                ordinal = choices[choice_index]
                choice_index += 1
                if not 0 <= ordinal < degree:
                    return -1, []
                following.append(cols[begin + ordinal])
        frontiers.append(following)
    output = [vertex for frontier in frontiers for vertex in frontier]
    return len(output), output
