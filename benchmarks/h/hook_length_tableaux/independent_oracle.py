"""Row-oriented hook-length oracle for the bounded tableau-count contract."""

MODULUS = 998244353


def expected(values, length=None):
    if values is None:
        return -1
    if length is None:
        length = len(values)
    if length != len(values) or not values or not 0 <= values[0] <= 65536 or len(values) != values[0] + 1:
        return -1
    rows = values[1:]
    if any(x < 1 or x > 1_000_000 for x in rows):
        return -1
    if any(rows[i] < rows[i + 1] for i in range(len(rows) - 1)):
        return -1
    total = sum(rows)
    if total > 1_000_000:
        return -1
    product = 1
    for row, width in enumerate(rows):
        for column in range(width):
            lo, hi = row + 1, len(rows)
            while lo < hi:
                middle = (lo + hi) // 2
                if rows[middle] > column:
                    lo = middle + 1
                else:
                    hi = middle
            product = product * (width - column + lo - row - 1) % MODULUS
    factorial = 1
    for i in range(2, total + 1):
        factorial = factorial * i % MODULUS
    return factorial * pow(product, MODULUS - 2, MODULUS) % MODULUS
