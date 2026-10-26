"""Oracle for the bounded binary64 TSVC s451 trigonometric map."""

import math

MAX_N = 64
MAX_INPUT_LENGTH = 1 + 2 * MAX_N
MAX_OUTPUT_ELEMENTS = MAX_N


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (input_is_null or not isinstance(values, (list, tuple))
            or input_length is not None and input_length != len(values)
            or len(values) < 3 or len(values) > MAX_INPUT_LENGTH):
        return -1, []
    raw_n = values[0]
    if (type(raw_n) not in (int, float) or not math.isfinite(float(raw_n))
            or not float(raw_n).is_integer() or not 1 <= raw_n <= MAX_N):
        return -1, []
    n = int(raw_n)
    if len(values) != 1 + 2*n:
        return -1, []
    operands = values[1:]
    if any(type(v) not in (int, float) or not math.isfinite(float(v))
           or abs(float(v)) > 10 for v in operands):
        return -1, []
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, []
    if output_is_null or (capacity is not None and capacity < n):
        return -2, []
    b, c = operands[:n], operands[n:]
    return n, [math.sin(float(x)) + math.cos(float(y)) for x, y in zip(b, c)]
