"""Unexecuted bit-vector and scalar-DP models for LCS length."""


def parse(values):
    if (not isinstance(values, (list, tuple)) or not 2 <= len(values) <= 515
            or any(type(value) is not int for value in values)):
        return None
    n, m = values[:2]
    if not 0 <= n <= 256 or not 0 <= m <= 256 or len(values) != 2+n+m:
        return None
    if any(not 0 <= symbol <= 255 for symbol in values[2:]):
        return None
    return values[2:2+n], values[2+n:]


def expected(values):
    parsed = parse(values)
    if parsed is None:
        return -1
    a, b = parsed
    masks = [0]*256
    for position, symbol in enumerate(a):
        masks[symbol] |= 1 << position
    row = 0
    for symbol in b:
        combined = row | masks[symbol]
        row = combined & (combined ^ (combined - ((row << 1) | 1)))
    return row.bit_count()


def independent(values):
    parsed = parse(values)
    if parsed is None:
        return -1
    a, b = parsed
    row = [0]*(len(a)+1)
    for symbol in b:
        previous = 0
        for j, other in enumerate(a, 1):
            old = row[j]
            row[j] = previous+1 if symbol == other else max(row[j], row[j-1])
            previous = old
    return row[-1]
