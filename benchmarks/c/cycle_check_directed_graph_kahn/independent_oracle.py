"""Transitive-closure reference for the bounded Kahn cycle profile."""


def expected_result(values):
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= 65
            or (len(values) - 1) % 2
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1
    n = values[0]
    if not 0 <= n <= 64:
        return -1
    reach = [0] * n
    for index in range(1, len(values), 2):
        u, v = values[index:index + 2]
        if not 0 <= u < n or not 0 <= v < n:
            return -1
        reach[u] |= 1 << v
    for k in range(n):
        for u in range(n):
            if reach[u] & (1 << k):
                reach[u] |= reach[k]
    return int(any(reach[v] & (1 << v) for v in range(n)))
