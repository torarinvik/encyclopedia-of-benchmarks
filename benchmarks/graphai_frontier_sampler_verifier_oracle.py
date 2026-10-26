"""Independent checker oracle for the deterministic GraphAIBench sampler profile."""
import math

MAX_INPUT_LENGTH = 124
MAX_OUTPUT_ELEMENTS = 88
STEPS = (3, 2, 2)


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (not isinstance(values, (list, tuple)) or len(values) > MAX_INPUT_LENGTH
            or type(output_is_null) is not bool or type(input_is_null) is not bool
            or input_is_null and len(values) != 0
            or input_length is not None and input_length != len(values)
            or output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0)):
        return -1, []
    if input_is_null or len(values) < 3:
        return -1, []
    if any(type(x) not in (int, float) or not math.isfinite(float(x)) for x in values):
        return -1, []
    n, m, roots_count = map(int, values[:3])
    if (any(float(values[i]) != (n, m, roots_count)[i] for i in range(3))
            or not 1 <= n <= 8 or not 0 <= m <= 24 or not 1 <= roots_count <= 4
            or len(values) != 4+n+m+22*roots_count):
        return -1, []
    root_pos = 3
    row_pos = root_pos+roots_count
    col_pos = row_pos+n+1
    choice_pos = col_pos+m
    raw_roots = values[root_pos:row_pos]
    raw_rows = values[row_pos:col_pos]
    raw_cols = values[col_pos:choice_pos]
    raw_choices = values[choice_pos:]
    if any(float(value) != math.trunc(float(value))
           for value in raw_roots+raw_rows+raw_cols+raw_choices):
        return -1, []
    roots = [int(value) for value in raw_roots]
    row = [int(value) for value in raw_rows]
    col = [int(value) for value in raw_cols]
    choice = [int(value) for value in raw_choices]
    if (row[0] != 0 or row[-1] != m or any(x < 0 or x > m for x in row)
            or any(row[i] > row[i+1] for i in range(n))
            or any(x < 0 or x >= n for x in roots+col)):
        return -1, []
    result_size = roots_count*22
    if output_is_null or output_capacity is not None and output_capacity < result_size:
        return -2, []
    all_levels = [roots[:]]
    cursor = 0
    for fanout in STEPS:
        next_level = []
        for parent in all_levels[-1]:
            start, stop = row[parent], row[parent+1]
            if start == stop:
                return -1, []
            for draw in range(fanout):
                edge_offset = choice[cursor]
                cursor += 1
                if edge_offset < 0 or edge_offset >= stop-start:
                    return -1, []
                next_level.append(col[start+edge_offset])
        all_levels.append(next_level)
    flattened = []
    for level in all_levels:
        flattened.extend(level)
    return len(flattened), flattened
