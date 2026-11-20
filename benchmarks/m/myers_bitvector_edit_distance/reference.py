"""Independent scalar model for the unexecuted bit-vector edit-distance draft."""

def expected(values):
    if (not isinstance(values, (tuple, list)) or not 2 <= len(values) <= 515
            or any(type(x) is not int for x in values)):
        return -1
    n, m = values[:2]
    if not 0 <= n <= 256 or not 0 <= m <= 256 or len(values) != 2+n+m:
        return -1
    if any(not 0 <= x <= 255 for x in values[2:]):
        return -1
    a, b = values[2:2+n], values[2+n:]
    row = list(range(n+1))
    for j, symbol in enumerate(b, 1):
        next_row = [j] + [0]*n
        for i, other in enumerate(a, 1):
            next_row[i] = min(row[i]+1, next_row[i-1]+1,
                              row[i-1]+(symbol != other))
        row = next_row
    return row[-1]
