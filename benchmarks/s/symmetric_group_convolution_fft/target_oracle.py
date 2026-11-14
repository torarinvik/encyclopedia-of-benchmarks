"""Unexecuted output-oriented small-group convolution reference."""
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
            or any(type(value) is not int or not 0 <= value < P for value in (*a, *b))):
        raise ValueError("invalid coefficient arrays")
    order = list(permutations(range(n)))
    index = {permutation: i for i, permutation in enumerate(order)}
    inverses = []
    for q in order:
        inverse = [0] * n
        for position, image in enumerate(q):
            inverse[image] = position
        inverses.append(inverse)
    result = []
    for target in order:
        total = 0
        for qi, inverse in enumerate(inverses):
            right = tuple(inverse[target[k]] for k in range(n))
            total += a[qi] * b[index[right]]
        result.append(total % P)
    return result
