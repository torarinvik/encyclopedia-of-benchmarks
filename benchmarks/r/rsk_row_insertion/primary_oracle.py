"""Forward Robinson–Schensted row insertion for bounded permutations."""

INVALID = -(1 << 63)
MAX_N = 8
MAX_VALID_INPUT_LENGTH = MAX_N + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
BASE = 9


def expected_result(values, input_is_null=False, input_length=None):
    if type(input_is_null) is not bool:
        return INVALID
    if input_length is not None and (
        type(input_length) is not int
        or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
    ):
        return INVALID
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID
    if input_length is not None and input_length != len(values):
        return INVALID
    if not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return INVALID

    n = values[0]
    if type(n) is not int or not 0 <= n <= MAX_N or len(values) != n + 1:
        return INVALID
    permutation = values[1:]
    if sorted(permutation) != list(range(n)):
        return INVALID
    if n == 0:
        return 0

    p_rows = []
    q_rows = []
    for step, raw_value in enumerate(permutation, start=1):
        value = raw_value + 1
        row = 0
        while True:
            if row == len(p_rows):
                p_rows.append([value])
                q_rows.append([step])
                break
            entries = p_rows[row]
            column = 0
            while column < len(entries) and entries[column] < value:
                column += 1
            if column == len(entries):
                entries.append(value)
                q_rows[row].append(step)
                break
            entries[column], value = value, entries[column]
            row += 1

    p_row_by_label = [0] * n
    q_row_by_label = [0] * n
    for row, entries in enumerate(p_rows):
        for value in entries:
            p_row_by_label[value - 1] = row
    for row, entries in enumerate(q_rows):
        for step in entries:
            q_row_by_label[step - 1] = row

    code = n
    for label in range(n):
        code = code * BASE + p_row_by_label[label] + 1
        code = code * BASE + q_row_by_label[label] + 1
    return code
