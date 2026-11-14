"""Direct scan and sort reference for bounded wavelet-matrix queries."""


def expected_output(values, input_is_null=False, input_length=None):
    if input_is_null or (input_length is not None and input_length != len(values)):
        return -1
    if len(values) < 2:
        return -1
    n = values[0]
    if not 1 <= n <= 64 or len(values) < n + 2:
        return -1
    data = values[1:n + 1]
    q = values[n + 1]
    if any(x < -1000 or x > 1000 for x in data) or not 0 <= q <= 128 or len(values) != n + 2 + 5*q:
        return -1
    result = 0
    for j in range(q):
        op, a, b, c, d = values[n + 2 + 5*j:n + 7 + 5*j]
        if op == 0:
            if not -1000 <= a <= 1000 or not -1 <= b < n:
                return -1
            answer = sum(x == a for x in data[:b + 1])
        elif op == 1:
            if not 0 <= a <= b < n or not 0 <= c <= b - a:
                return -1
            answer = sorted(data[a:b + 1])[c]
        elif op == 2:
            if not 0 <= a <= b < n or not -1000 <= c <= d <= 1000:
                return -1
            answer = sum(c <= x <= d for x in data[a:b + 1])
        else:
            return -1
        result += (j + 1) * (answer + 1_000_001)
    return result
