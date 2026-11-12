"""Knuth-bounded optimal-BST primary oracle."""

MAX_N = 64
MAX_FREQUENCY = 1_000_000
MAX_INPUT_LENGTH = MAX_N + 1
MAX_COST = MAX_N * MAX_N * MAX_FREQUENCY


def _decode(values):
    if (not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    n = values[0]
    if type(n) is not int or not 1 <= n <= MAX_N or len(values) != n + 1:
        return None
    frequencies = tuple(values[1:])
    if any(not 0 <= x <= MAX_FREQUENCY for x in frequencies):
        return None
    return frequencies


def expected_result(values):
    frequencies = _decode(values)
    if frequencies is None:
        return -1
    n = len(frequencies)
    prefix = [0] * (n + 1)
    for i, value in enumerate(frequencies):
        prefix[i + 1] = prefix[i] + value
    cost = [[0] * n for _ in range(n)]
    root_opt = [[0] * n for _ in range(n)]
    for i, value in enumerate(frequencies):
        cost[i][i] = value
        root_opt[i][i] = i
    for width in range(2, n + 1):
        for left in range(n - width + 1):
            right = left + width - 1
            total = prefix[right + 1] - prefix[left]
            first = max(left, root_opt[left][right - 1])
            last = min(right, root_opt[left + 1][right])
            best_cost = None
            best_root = first
            for root in range(first, last + 1):
                candidate = total
                if root > left:
                    candidate += cost[left][root - 1]
                if root < right:
                    candidate += cost[root + 1][right]
                if best_cost is None or candidate < best_cost:
                    best_cost = candidate
                    best_root = root
            cost[left][right] = best_cost
            root_opt[left][right] = best_root
    return cost[0][n - 1]
