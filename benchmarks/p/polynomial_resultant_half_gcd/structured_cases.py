"""Unexecuted structured resultant cases for later suite integration."""

P = 998244353


def sparse(degree, constant, leading):
    if degree < 1:
        raise ValueError("degree must be positive")
    return [constant] + [0] * (degree - 1) + [leading]


def frame(a, b):
    return [len(a) - 1, len(b) - 1, *a, *b]


def continuants(degree):
    """Return adjacent monic remainders in a deliberately long chain.

    Starting with r_0=3 and r_1=x+2, set r_k=x*r_(k-1)+r_(k-2).
    Each Euclidean step has quotient x, and the terminal constant is 3.
    Adjacent degrees have even product and every divisor is monic, so their
    resultant remains 3 throughout the chain.
    """
    previous = [3]
    current = [2, 1]
    for _ in range(2, degree + 1):
        following = [0] * (len(current) + 1)
        for i, value in enumerate(current):
            following[i + 1] = value
        for i, value in enumerate(previous):
            following[i] = (following[i] + value) % P
        previous, current = current, following
    return current, previous


def cases():
    """Yield (name, input, result), including recursive and NTT boundaries."""
    # Res(x^d+1, c*x^e) = c^d: all e roots of x^e are zero.
    for d in (63, 64, 65, 66, 127, 128, 129):
        a = sparse(d, 1, 1)
        b = sparse(d - 1, 0, 7)
        expected = pow(7, d, P)
        yield f"monomial_divisor_{d}", frame(a, b), expected
        # Consecutive degrees have even product, so swapping adds no sign.
        yield f"monomial_divisor_swapped_{d}", frame(b, a), expected

    # x-1 divides both inputs, including across the recursive cutoff.
    for d in (65, 129):
        a = sparse(d, P - 1, 1)
        b = sparse(d - 1, P - 1, 1)
        yield f"shared_linear_factor_{d}", frame(a, b), 0

    # Odd degree product exercises the sign on swapping unlike consecutive
    # degrees. The second polynomial has 63 roots at zero.
    a = sparse(65, 1, 1)
    b = sparse(63, 0, 11)
    expected = pow(11, 65, P)
    yield "odd_degree_product", frame(a, b), expected
    yield "odd_degree_product_swapped", frame(b, a), (-expected) % P

    for degree in (65, 129, 257):
        a, b = continuants(degree)
        yield f"long_quotient_chain_{degree}", frame(a, b), 3
        yield f"long_quotient_chain_swapped_{degree}", frame(b, a), 3

    # Highest permitted degree sum, exercising the full scalar frame bound.
    a = sparse(50000, 1, 1)
    b = sparse(49998, 0, 3)
    yield "maximum_degree_sum", frame(a, b), pow(3, 50000, P)

    # An extra word is rejected while staying within the harness limit.
    almost_maximum = frame(sparse(49999, 1, 1), sparse(49998, 0, 3))
    yield "maximum_parseable_extra_word", [*almost_maximum, 0], -1
