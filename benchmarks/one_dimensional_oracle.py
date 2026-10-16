"""Runtime oracle for the pinned 31-cell one-dimensional automaton."""

MAX_INPUT_LENGTH = 1
MAX_OUTPUT_BYTES = 17 * 31 * 3


def expected_output(values):
    if (not isinstance(values, (list, tuple)) or len(values) != 1
            or type(values[0]) is not int or not -(2**63) <= values[0] < 2**63):
        return -1, b""
    code = values[0]
    if code < 0 or code > 11_111_111:
        return -1, b""
    digits = str(code)
    if any(ch not in "01" for ch in digits):
        return -1, b""
    rule = [int(ch) for ch in digits.zfill(8)]
    rows = [[0] * 31 for _ in range(17)]
    rows[0][15] = 1
    for r in range(16):
        for c in range(31):
            left = rows[r][c - 1] if c else 0
            right = rows[r][c + 1] if c < 30 else 0
            pattern = (left << 2) | (rows[r][c] << 1) | right
            rows[r + 1][c] = rule[7 - pattern]
    output = bytes(channel for row in rows for cell in row
                   for channel in ((0 if cell else 255),) * 3)
    return len(output), output
