"""Unexecuted, independently written GF(2) quadratic-form reduction draft.

This is a construction reference, not an implementation of the benchmark
ABI.  It works on integer bit masks and returns rows of P for y = P*x.
"""


def _evaluate(rows, x):
    answer = 0
    for i, row in enumerate(rows):
        if (x >> i) & 1:
            answer ^= (row & x).bit_count() & 1
    return answer


def _inverse_rows(columns, n):
    # Augment the column-built matrix with identity and row-reduce it.
    left = [sum(((columns[j] >> i) & 1) << j for j in range(n))
            for i in range(n)]
    right = [1 << i for i in range(n)]
    for col in range(n):
        pivot = next((i for i in range(col, n) if (left[i] >> col) & 1), None)
        if pivot is None:
            raise ValueError("reduction generated a singular basis")
        left[col], left[pivot] = left[pivot], left[col]
        right[col], right[pivot] = right[pivot], right[col]
        for row in range(n):
            if row != col and (left[row] >> col) & 1:
                left[row] ^= left[col]
                right[row] ^= right[col]
    return right


def reduce_form(n, rows):
    if (type(n) is not int or not 1 <= n <= 100
            or not isinstance(rows, (tuple, list)) or len(rows) != n
            or any(type(row) is not int or row < 0 or row >= 1 << n
                   or row & ((1 << i) - 1) for i, row in enumerate(rows))):
        raise ValueError("invalid upper-triangular form")

    def q(x):
        return _evaluate(rows, x)

    def polar(x, y):
        return q(x ^ y) ^ q(x) ^ q(y)

    remaining = [1 << i for i in range(n)]
    hyperbolic, anisotropic = [], []
    while True:
        pair = next(((i, j) for i in range(len(remaining))
                     for j in range(i + 1, len(remaining))
                     if polar(remaining[i], remaining[j])), None)
        if pair is None:
            break
        i, j = pair
        u, v = remaining[i], remaining[j]
        rest = [w for index, w in enumerate(remaining) if index not in (i, j)]
        remaining = [w ^ (u if polar(w, v) else 0) ^ (v if polar(w, u) else 0)
                     for w in rest]
        qu, qv = q(u), q(v)
        if qu and qv:
            anisotropic.append((u, v))
        else:
            if qu:
                u ^= v
            elif qv:
                v ^= u
            hyperbolic.append((u, v))

    # Two anisotropic planes combine into two hyperbolic planes.
    while len(anisotropic) >= 2:
        a, b = anisotropic.pop()
        c, d = anisotropic.pop()
        hyperbolic.append((a ^ c, b ^ c))
        f = d ^ a ^ b
        hyperbolic.append((f, f ^ c))

    pivot = next((i for i, vector in enumerate(remaining) if q(vector)), None)
    linear = None
    if pivot is not None:
        linear = remaining.pop(pivot)
        remaining = [vector ^ (linear if q(vector) else 0) for vector in remaining]

    # A nonzero radical coordinate absorbs the final anisotropic plane.
    if linear is not None and anisotropic:
        u, v = anisotropic.pop()
        hyperbolic.append((u ^ linear, v ^ linear))

    columns = [vector for pair in hyperbolic for vector in pair]
    for pair in anisotropic:
        columns.extend(pair)
    if linear is not None:
        columns.append(linear)
    columns.extend(remaining)
    if len(columns) != n:
        raise ValueError("reduction lost a basis vector")
    return _inverse_rows(columns, n), len(hyperbolic), len(anisotropic), int(linear is not None)
