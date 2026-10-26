"""Primary pair-state DAG oracle for interval-graph minimal dominating sets."""

MAX_INPUT_LENGTH = 25
MAX_OUTPUT_BYTES = 8
MAX_N = 12


def _intersects(a, b):
    return a[0] <= b[1] and b[0] <= a[1]


def _dag_count(intervals):
    n = len(intervals)
    starts = [x[0] for x in intervals]
    ends = [x[1] for x in intervals]
    min_end, max_start = min(ends), max(starts)
    p_single = [None] * n
    ncs = [None] * n
    nce = [None] * n
    for i, x in enumerate(intervals):
        p_single[i] = min((z[1] for z in intervals if _intersects(x, z)), default=None)
        right = [z for z in intervals if z[0] > x[1]]
        if right:
            ncs[i] = min(z[0] for z in right)
            nce[i] = min(z[1] for z in right)
    valid = [[False] * n for _ in range(n)]
    private_pair = [[None] * n for _ in range(n)]
    for i in range(n):
        for j in range(i + 1, n):
            private_pair[i][j] = min(
                (z[1] for z in intervals if _intersects(intervals[j], z) and not _intersects(intervals[i], z)),
                default=None,
            )
            valid[i][j] = (
                ncs[i] is not None and p_single[i] is not None
                and p_single[i] < starts[j] <= nce[i]
                and ends[j] >= ncs[i]
            )
    ways = [[0] * n for _ in range(n)]
    for j in range(1, n):
        for i in range(j):
            if not valid[i][j]:
                continue
            if starts[i] <= min_end:
                ways[i][j] += 1
            if ways[i][j] == 0:
                continue
            for k in range(j + 1, n):
                if (valid[j][k] and private_pair[i][j] is not None
                        and private_pair[i][j] < starts[k] <= nce[j]):
                    ways[j][k] += ways[i][j]
    singleton_count = sum(s <= min_end and e >= max_start for s, e in intervals)
    path_count = sum(ways[i][j] for i in range(n) for j in range(i + 1, n) if ends[j] >= max_start)
    return singleton_count + path_count


def evaluate(values):
    if values is None or len(values) < 3 or len(values) > MAX_INPUT_LENGTH:
        return -1, b""
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != 1 + 2 * n:
        return -1, b""
    intervals = [(values[1 + 2 * i], values[2 + 2 * i]) for i in range(n)]
    endpoints = [x for pair in intervals for x in pair]
    if any(x < -100 or x > 100 for x in endpoints):
        return -1, b""
    if any(s >= e for s, e in intervals):
        return -1, b""
    if any(intervals[i][0] >= intervals[i + 1][0] for i in range(n - 1)):
        return -1, b""
    if len(set(endpoints)) != len(endpoints):
        return -1, b""
    return 8, _dag_count(intervals).to_bytes(8, "little", signed=True)
