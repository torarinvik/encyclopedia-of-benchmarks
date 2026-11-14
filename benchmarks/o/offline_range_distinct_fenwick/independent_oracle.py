"""Unexecuted direct-set reference for bounded static distinct queries."""


def expected_output(values, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list)) or not 3 <= len(values) <= 195
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or any(type(value) is not int or value < -(1 << 63) or value >= 1 << 63 for value in values)):
        return -1
    n, q = values[:2]
    if not 1 <= n <= 64 or not 0 <= q <= 64 or len(values) != 2+n+2*q:
        return -1
    data = values[2:2+n]
    if any(value < 0 or value > 255 for value in data):
        return -1
    result = 0
    for index in range(q):
        left, right = values[2+n+2*index:4+n+2*index]
        if left < 0 or left > right or right > n:
            return -1
        result += (index+1) * len(set(data[left:right]))
    return result
