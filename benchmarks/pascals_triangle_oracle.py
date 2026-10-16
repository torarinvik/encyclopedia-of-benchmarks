"""Oracle for the pinned TypeScript Pascal triangle final-row function."""

MAX_INPUT_LENGTH = 1
MAX_ROWS = 31
MODULUS = 1_000_000_007


def expected_result(values):
    if (not isinstance(values, (list, tuple)) or len(values) != 1
            or type(values[0]) is not int or not 1 <= values[0] <= MAX_ROWS):
        return -1
    rows = values[0]
    row = [1]
    for _ in range(1, rows):
        nxt = [1] * (len(row) + 1)
        for j in range(1, len(row)):
            nxt[j] = row[j - 1] + row[j]
        row = nxt
    result = 0
    for coefficient in row:
        result = (result * 31 + coefficient) % MODULUS
    return result
