"""Brent's checkpoint-doubling cycle-parameter reference."""


def expected_output(values, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple)) or not 3 <= len(values) <= 67
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return -1
    n, start = values[:2]
    if not 1 <= n <= 64 or not 0 <= start < n or len(values) != n + 2:
        return -1
    if any(not 0 <= v < n for v in values[2:]):
        return -1
    def successor(node):
        return values[node + 2]
    checkpoint, moving = start, successor(start)
    power = period = 1
    while checkpoint != moving:
        if power == period:
            checkpoint, power, period = moving, power * 2, 0
        moving = successor(moving)
        period += 1
    left = right = start
    for _ in range(period):
        right = successor(right)
    tail = 0
    while left != right:
        left, right = successor(left), successor(right)
        tail += 1
    return 65 * tail + period
