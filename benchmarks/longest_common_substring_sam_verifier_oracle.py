"""Independent one-row dynamic-programming longest-common-substring oracle."""

from collections.abc import Sequence


def evaluate(values: Sequence[int] | None) -> int:
    if values is None or not isinstance(values, (list, tuple)) or not 2 <= len(values) <= 515 or any(type(x) is not int for x in values):
        return -1
    n = values[0]
    if not 0 <= n <= 256 or len(values) < n+2:
        return -1
    m = values[n+1]
    if not 0 <= m <= 256 or len(values) != 2+n+m:
        return -1
    left, right = values[1:n+1], values[n+2:]
    if any(not 32 <= x <= 126 for x in (*left, *right)):
        return -1
    row = [0]*(m+1); best = 0
    for x in left:
        for j in range(m, 0, -1):
            row[j] = row[j-1]+1 if x == right[j-1] else 0
            best = max(best, row[j])
    return best
