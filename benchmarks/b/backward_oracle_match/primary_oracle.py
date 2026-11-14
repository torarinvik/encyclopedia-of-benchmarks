"""Bounded factor-oracle backward-search draft."""


def expected_output(values, input_is_null=False, input_length=None):
    if input_length is not None and not input_is_null and input_length != len(values):
        return -2
    if input_is_null or len(values) < 2:
        return -2
    n, m = values[:2]
    if not (0 <= n <= 4096 and 0 <= m <= 63 and len(values) == 2 + n + m):
        return -2
    if any(x < 97 or x > 122 for x in values[2:]):
        return -2
    if m == 0:
        return 0
    if m > n:
        return -1
    transition = [[-1] * 26 for _ in range(m + 1)]
    suffix = [-1] * (m + 1)
    for i in range(m):
        letter = values[2 + n + m - 1 - i] - 97
        transition[i][letter] = i + 1
        k = suffix[i]
        while k >= 0 and transition[k][letter] < 0:
            transition[k][letter] = i + 1
            k = suffix[k]
        suffix[i + 1] = 0 if k < 0 else transition[k][letter]
    start = 0
    while start <= n - m:
        state, remaining, shift = 0, m, m
        while remaining:
            remaining -= 1
            state = transition[state][values[2 + start + remaining] - 97]
            if state < 0:
                shift = remaining + 1
                break
            if remaining == 0:
                return start
        start += shift
    return -1
