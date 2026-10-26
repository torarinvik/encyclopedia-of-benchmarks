"""Oracle for the bounded TSVC s423 offset-64 anti-dependence profile."""

MIN_N = 65
MAX_N = 128
MAX_INPUT_LENGTH = MAX_N + 65


def expected_result(values, input_is_null=False, input_length=None):
    if (input_is_null or not isinstance(values, (list, tuple))
            or input_length is not None and input_length != len(values)
            or len(values) < MIN_N + 65 or len(values) > MAX_INPUT_LENGTH):
        return -1
    if type(values[0]) is not int or not MIN_N <= values[0] <= MAX_N:
        return -1
    n = values[0]
    if len(values) != n + 65:
        return -1
    data = values[1:]
    if any(type(value) is not int or not 0 <= value <= 2 for value in data):
        return -1
    a = data[:n]
    x = [0] * (n + 64)
    x[:64] = data[n:]
    x[64:] = [1] * n
    for i in range(n - 1):
        x[i + 1] = x[i + 64] + a[i]
    return sum(x[:n])
