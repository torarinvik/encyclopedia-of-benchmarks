"""Independent exhaustive-subset verifier for bounded interval graphs."""

MAX_INPUT_LENGTH = 25
MAX_OUTPUT_BYTES = 8


def _overlap(a, b):
    return a[0] <= b[1] and b[0] <= a[1]


def evaluate(values):
    if values is None or len(values) < 3 or len(values) > MAX_INPUT_LENGTH:
        return -1, b""
    n = values[0]
    if n < 1 or n > 12 or len(values) != 1 + 2 * n:
        return -1, b""
    intervals = [(values[1 + 2 * i], values[2 + 2 * i]) for i in range(n)]
    endpoints = [x for pair in intervals for x in pair]
    if (any(x < -100 or x > 100 for x in endpoints)
            or any(s >= e for s, e in intervals)
            or any(intervals[i][0] >= intervals[i + 1][0] for i in range(n - 1))
            or len(set(endpoints)) != len(endpoints)):
        return -1, b""
    adjacency = [[_overlap(intervals[i], intervals[j]) for j in range(n)] for i in range(n)]
    count = 0
    for mask in range(1 << n):
        dominated = [False] * n
        for i in range(n):
            if mask >> i & 1:
                for j in range(n):
                    dominated[j] |= adjacency[i][j]
        if not all(dominated):
            continue
        minimal = True
        for i in range(n):
            if mask >> i & 1:
                if all(any((mask >> j & 1) and j != i and adjacency[j][v] for j in range(n))
                       for v in range(n) if adjacency[i][v]):
                    minimal = False
                    break
        if minimal:
            count += 1
    return 8, count.to_bytes(8, "little", signed=True)
