"""Independent closed-form oracle for the bounded Ackermann profile."""

I64_MIN = -(2**63)
I64_MAX = 2**63 - 1


def expected_result(m: int, n: int) -> int:
    """Return A(m, n) for the suite's domain, or -1 outside it.

    The ports use the source's direct recursive definition. This oracle uses
    the closed forms for rows zero through three, keeping verification
    independent from that recursion.
    """
    if (type(m) is not int or type(n) is not int
            or not I64_MIN <= m <= I64_MAX
            or not I64_MIN <= n <= I64_MAX
            or not 0 <= m <= 3 or not 0 <= n <= 8):
        return -1
    if m == 0:
        return n + 1
    if m == 1:
        return n + 2
    if m == 2:
        return 2 * n + 3
    return (1 << (n + 3)) - 3
