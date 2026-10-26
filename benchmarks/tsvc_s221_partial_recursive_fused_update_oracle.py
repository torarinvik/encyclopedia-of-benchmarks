"""Oracle for the bounded TSVC s221 fused update and recurrence."""

import math

MAX_N = 64
MAX_INPUT_LENGTH = 1 + 4 * MAX_N
MAX_OUTPUT_ELEMENTS = 2 * MAX_N


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (input_is_null or not isinstance(values, (list, tuple))
            or input_length is not None and input_length != len(values)
            or len(values) < 5 or len(values) > MAX_INPUT_LENGTH):
        return -1, []
    raw_n = values[0]
    if (type(raw_n) not in (int, float) or not math.isfinite(float(raw_n))
            or not float(raw_n).is_integer() or not 1 <= raw_n <= MAX_N):
        return -1, []
    n = int(raw_n)
    if len(values) != 1 + 4*n:
        return -1, []
    data = values[1:]
    if any(type(v) not in (int, float) or not math.isfinite(float(v))
           or not float(v).is_integer() or abs(float(v)) > 2 for v in data):
        return -1, []
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, []
    required = 2*n
    if output_is_null or (capacity is not None and capacity < required):
        return -2, []
    a = [float(v) for v in data[:n]]
    b = [float(v) for v in data[n:2*n]]
    c = data[2*n:3*n]
    d = data[3*n:]
    for i in range(1, n):
        a[i] = a[i] + float(c[i]) * float(d[i])
        b[i] = (b[i-1] + a[i]) + float(d[i])
    return required, a + b
