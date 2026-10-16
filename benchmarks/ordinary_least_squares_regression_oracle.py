"""Runtime oracle for centered univariate ordinary least squares."""
import struct

MAX_INPUT_LENGTH = 65
MAX_OUTPUT_BYTES = 16
INVALID_RESULT = -1


def expected_output(values):
    if (not isinstance(values, (list, tuple)) or len(values) < 1
            or any(type(x) is not int or not -(2**63) <= x < 2**63 for x in values)):
        return INVALID_RESULT, b""
    n = values[0]
    if not 2 <= n <= 32 or len(values) != 1 + 2 * n:
        return INVALID_RESULT, b""
    xs, ys = values[1::2], values[2::2]
    if any(not -10000 <= x <= 10000 for x in xs + ys):
        return INVALID_RESULT, b""
    xm, ym = sum(xs) / n, sum(ys) / n
    denominator = sum((x - xm) ** 2 for x in xs)
    if denominator == 0:
        return INVALID_RESULT, b""
    slope = sum((x - xm) * (y - ym) for x, y in zip(xs, ys)) / denominator
    intercept = ym - slope * xm
    return 16, struct.pack("<dd", intercept, slope)
