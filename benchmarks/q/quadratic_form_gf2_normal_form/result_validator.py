"""Unexecuted symbolic validator for a proposed GF(2) quadratic normal form.

Rows encode binary linear forms by their set bits.  The input quadratic form
uses one upper-triangular bit row per input coordinate; diagonal bits represent
square terms.  Output rows encode y = P x, not its inverse.
"""


def _rank(rows, n):
    basis = [0] * n
    rank = 0
    for row in rows:
        value = row
        while value:
            pivot = value.bit_length() - 1
            if basis[pivot]:
                value ^= basis[pivot]
            else:
                basis[pivot] = value
                rank += 1
                break
    return rank


def _original(rows, x):
    value = 0
    for i, row in enumerate(rows):
        if (x >> i) & 1:
            value ^= (row & x).bit_count() & 1
    return value


def _normal(y, r, s, t):
    value = 0
    for k in range(r):
        value ^= ((y >> (2*k)) & 1) & ((y >> (2*k+1)) & 1)
    position = 2*r
    if s:
        left, right = (y >> position) & 1, (y >> (position+1)) & 1
        value ^= left ^ (left & right) ^ right
        position += 2
    if t:
        value ^= (y >> position) & 1
    return value


def validate(n, upper_rows, transform_rows, r, s, t):
    """Check input structure, invertibility, and equality of quadratic forms.

    Evaluating each basis vector and each pair determines all coefficients
    over GF(2), without relying on the reduction algorithm or enumerating 2^n
    assignments.  Invalid data or a mismatched result returns False.
    """
    if (type(n) is not int or not 1 <= n <= 100
            or not isinstance(upper_rows, (tuple, list))
            or not isinstance(transform_rows, (tuple, list))
            or len(upper_rows) != n or len(transform_rows) != n
            or any(type(v) is not int or v < 0 or v >= 1 << n
                   for v in (*upper_rows, *transform_rows))
            or any(row & ((1 << i) - 1) for i, row in enumerate(upper_rows))
            or any(type(v) is not int or v < 0 for v in (r, s, t))
            or s + t > 1 or 2*r + 2*s + t > n):
        return False
    if _rank(transform_rows, n) != n:
        return False

    def normal_at(x):
        y = 0
        for i, row in enumerate(transform_rows):
            y |= ((row & x).bit_count() & 1) << i
        return _normal(y, r, s, t)

    for i in range(n):
        ei = 1 << i
        if _original(upper_rows, ei) != normal_at(ei):
            return False
        for j in range(i + 1, n):
            x = ei | (1 << j)
            if _original(upper_rows, x) != normal_at(x):
                return False
    return True
