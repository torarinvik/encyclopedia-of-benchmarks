"""Unexecuted small direct reference; not the scalable benchmark kernel."""
from itertools import permutations
from math import factorial

P = 998244353


def convolve(n, a, b):
    if type(n) is not int or not 1 <= n <= 9:
        raise ValueError("degree outside the proposed contract")
    if n > 5:
        raise ValueError("direct reference is limited to degree five")
    count = factorial(n)
    if (not isinstance(a, (list, tuple)) or not isinstance(b, (list, tuple))
            or len(a) != count or len(b) != count
            or any(type(x) is not int or not 0 <= x < P for x in (*a, *b))):
        raise ValueError("invalid coefficient arrays")
    order = list(permutations(range(n)))
    index = {permutation: i for i, permutation in enumerate(order)}
    out = [0] * count
    for i, q in enumerate(order):
        for j, r in enumerate(order):
            target = tuple(q[r[k]] for k in range(n))
            out[index[target]] = (out[index[target]] + a[i]*b[j]) % P
    return out
