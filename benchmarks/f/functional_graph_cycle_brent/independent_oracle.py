"""Cycle parameters from first-visit positions rather than checkpoint search."""


def expected_output(values, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list)) or not 3 <= len(values) <= 67
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or any(type(x) is not int or x < -(1 << 63) or x >= 1 << 63 for x in values)):
        return -1
    n, node = values[:2]
    if not 1 <= n <= 64 or not 0 <= node < n or len(values) != n + 2:
        return -1
    if any(v < 0 or v >= n for v in values[2:]):
        return -1
    seen = {}
    while node not in seen:
        seen[node] = len(seen)
        node = values[node + 2]
    tail = seen[node]
    return 65 * tail + len(seen) - tail
