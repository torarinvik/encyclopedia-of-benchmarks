"""Small, deliberately quadratic reference for half-GCD matrix reductions.

This draft is intended for future differential checks; it has not been run.
It computes transformations, not resultant factors. Coefficients are stored
in ascending order and the empty tuple denotes zero.
"""

P = 998244353


def trim(a):
    a = list(a)
    while a and a[-1] == 0:
        a.pop()
    return tuple(a)


def add(a, b):
    return trim(((a[i] if i < len(a) else 0) +
                 (b[i] if i < len(b) else 0)) % P
                for i in range(max(len(a), len(b))))


def neg(a):
    return trim((-x) % P for x in a)


def mul(a, b):
    if not a or not b:
        return ()
    out = [0] * (len(a) + len(b) - 1)
    for i, x in enumerate(a):
        for j, y in enumerate(b):
            out[i + j] = (out[i + j] + x * y) % P
    return trim(out)


def divide(a, b):
    if not b:
        raise ZeroDivisionError("polynomial division by zero")
    remainder = list(a)
    quotient = [0] * max(0, len(a) - len(b) + 1)
    inverse = pow(b[-1], P - 2, P)
    while len(remainder) >= len(b):
        shift = len(remainder) - len(b)
        coefficient = remainder[-1] * inverse % P
        quotient[shift] = coefficient
        for i, value in enumerate(b):
            remainder[shift + i] = (remainder[shift + i] - coefficient * value) % P
        while remainder and remainder[-1] == 0:
            remainder.pop()
    return trim(quotient), tuple(remainder)


IDENTITY = (((1,), ()), ((), (1,)))


def compose(left, right):
    return tuple(tuple(add(mul(left[i][0], right[0][j]),
                           mul(left[i][1], right[1][j]))
                       for j in range(2)) for i in range(2))


def apply(matrix, a, b):
    return tuple(add(mul(row[0], a), mul(row[1], b)) for row in matrix)


def step(q):
    return (((), (1,)), ((1,), neg(q)))


def direct_reduction(a, b):
    """Return the elementary-step matrix for the prescribed degree cutoff."""
    if not a or (b and len(a) <= len(b)):
        raise ValueError("expected nonzero a with degree strictly greater than b")
    threshold = len(a) // 2
    result = IDENTITY
    while b and len(b) > threshold:
        q, r = divide(a, b)
        result = compose(step(q), result)
        a, b = b, r
    return result


def recursive_reduction(a, b, cutoff=2):
    """Mirror the recursive degree boundaries using schoolbook arithmetic.

    The low default cutoff makes small future test cases exercise recursion.
    Inputs must already be canonical field polynomials in strict degree order.
    """
    if not a or (b and len(a) <= len(b)):
        raise ValueError("expected nonzero a with degree strictly greater than b")
    if cutoff < 1:
        raise ValueError("cutoff must be positive")
    threshold = len(a) // 2
    if not b or len(b) <= threshold:
        return IDENTITY
    if len(a) - 1 <= cutoff:
        return direct_reduction(a, b)

    first = recursive_reduction(a[threshold:], b[threshold:], cutoff)
    c, d = apply(first, a, b)
    if not d or len(d) <= threshold:
        return first
    q, r = divide(c, d)
    prefix = compose(step(q), first)
    if not r:
        return prefix
    shift = 2 * threshold - (len(d) - 1)
    upper_a, upper_b = d[shift:], r[shift:]
    if not upper_b:
        return prefix
    return compose(recursive_reduction(upper_a, upper_b, cutoff), prefix)
