"""Independent bounded oracle for wavelet-tree rank, quantile, and value counts."""
MAX_ITEMS = 64
MAX_QUERIES = 128
MAX_INPUT_VALUES = MAX_ITEMS + 2 + 5 * MAX_QUERIES
OFFSET = 1_000_001


def expected_result(values: list[int]) -> int:
    if not isinstance(values, list) or len(values) < 2 or len(values) > MAX_INPUT_VALUES:
        return -1
    if any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values):
        return -1
    n = values[0]
    if not 1 <= n <= MAX_ITEMS or len(values) < n + 2:
        return -1
    data = values[1:n + 1]
    if any(not -1000 <= x <= 1000 for x in data):
        return -1
    q = values[n + 1]
    if not 0 <= q <= MAX_QUERIES or len(values) != n + 2 + 5 * q:
        return -1
    total = 0
    for j in range(q):
        op, a, b, c, d = values[n + 2 + 5*j:n + 7 + 5*j]
        if op == 0:  # occurrences of value a in prefix [0,b]
            if not -1000 <= a <= 1000 or not -1 <= b < n:
                return -1
            result = sum(x == a for x in data[:b + 1])
        elif op == 1:  # zero-based kth element in inclusive [a,b]
            if not 0 <= a <= b < n or not 0 <= c <= b - a:
                return -1
            result = sorted(data[a:b + 1])[c]
        elif op == 2:  # values in [c,d] over positions [a,b]
            if not 0 <= a <= b < n or c > d or not -1000 <= c <= 1000 or not -1000 <= d <= 1000:
                return -1
            result = sum(c <= x <= d for x in data[a:b + 1])
        else:
            return -1
        total += (j + 1) * (result + OFFSET)
    return total
