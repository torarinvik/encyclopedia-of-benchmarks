"""Bit-parallel backward search reference for the bounded benchmark."""


def expected_output(values, input_is_null=False, input_length=None):
    if input_length is not None and not input_is_null and input_length != len(values):
        return -2
    if input_is_null or len(values) < 2:
        return -2
    n, m = values[:2]
    if not (0 <= n <= 4096 and 0 <= m <= 63 and len(values) == 2 + n + m):
        return -2
    if any(value < 97 or value > 122 for value in values[2:]):
        return -2
    if m == 0:
        return 0
    if m > n:
        return -1

    masks = [0] * 26
    for i in range(m):
        masks[values[2 + n + i] - 97] |= 1 << (m - i - 1)
    start = 0
    while start <= n - m:
        remaining, shift = m, m
        states = (1 << m) - 1
        while remaining and states:
            remaining -= 1
            states &= masks[values[2 + start + remaining] - 97]
            if states:
                if remaining == 0:
                    return start
                shift = remaining
            states = (states << 1) & ((1 << m) - 1)
        start += shift
    return -1
