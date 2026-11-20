"""Quadratic direct-successor scans plus per-start alternating simulation."""

try:
    from .primary_oracle import INVALID, MAX_N, MIN_VALUE, MAX_VALUE
except ImportError:
    from primary_oracle import INVALID, MAX_N, MIN_VALUE, MAX_VALUE


def _valid(values, input_is_null=False, input_length=None):
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return False
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return False
    if len(values) < 2 or len(values) > MAX_N + 1:
        return False
    n = values[0]
    return (type(n) is int and 1 <= n <= MAX_N and len(values) == n + 1
            and all(type(value) is int and MIN_VALUE <= value <= MAX_VALUE
                    for value in values[1:]))


def expected(values, input_is_null=False, input_length=None):
    if not _valid(values, input_is_null, input_length):
        return INVALID
    data = list(values[1:])
    n = len(data)
    odd_next = [-1] * n
    even_next = [-1] * n
    for index in range(n - 1):
        best_odd = None
        best_even = None
        for target in range(index + 1, n):
            if data[target] >= data[index]:
                candidate = (data[target], target)
                if best_odd is None or candidate < best_odd:
                    best_odd = candidate
            if data[target] <= data[index]:
                candidate = (-data[target], target)
                if best_even is None or candidate < best_even:
                    best_even = candidate
        if best_odd is not None:
            odd_next[index] = best_odd[1]
        if best_even is not None:
            even_next[index] = best_even[1]

    good_starts = 0
    for start in range(n):
        position = start
        odd_turn = True
        while position != n - 1:
            position = odd_next[position] if odd_turn else even_next[position]
            if position < 0:
                break
            odd_turn = not odd_turn
        if position == n - 1:
            good_starts += 1
    return good_starts
