"""Independent oracle for the bounded TSVC vtvtv product-map profile."""

import math

MAX_N = 64
MAX_INPUT_LENGTH = 1 + 3 * MAX_N
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH
MAX_OUTPUT_ELEMENTS = MAX_N


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (input_is_null or not isinstance(values, (list, tuple))
            or input_length is not None and input_length != len(values)
            or len(values) < 4 or len(values) > MAX_INPUT_LENGTH):
        return -1, []
    raw_n = values[0]
    if (type(raw_n) not in (int, float) or not math.isfinite(float(raw_n))
            or not float(raw_n).is_integer() or not 1 <= raw_n <= MAX_N):
        return -1, []
    n = int(raw_n)
    if len(values) != 1 + 3 * n:
        return -1, []
    data = values[1:]
    if any(type(v) not in (int, float) or not math.isfinite(float(v))
           or not float(v).is_integer() or abs(float(v)) > 2 for v in data):
        return -1, []
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, []
    if output_is_null or (capacity is not None and capacity < n):
        return -2, []
    a = [float(v) for v in data[:n]]
    b = data[n:2*n]
    c = data[2*n:]
    # Keep the pinned C expression's left-associative binary64 order.
    for i in range(n):
        a[i] = (a[i] * float(b[i])) * float(c[i])
    return n, a
