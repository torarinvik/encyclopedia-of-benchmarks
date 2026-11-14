"""Direct Euclidean-remainder resultant for small polynomial frames."""

P = 998244353


def parse(values):
    if values is None or len(values) < 4:
        return None
    m, n = values[:2]
    if (not 0 <= m <= 50000 or not 0 <= n <= 50000 or m+n > 99998
            or len(values) != m+n+4 or any(not 0 <= x < P for x in values[2:])):
        return None
    a = list(values[2:3+m])
    b = list(values[3+m:])
    return None if a[-1] == 0 or b[-1] == 0 else (a, b)


def expected(values):
    parsed = parse(values)
    if parsed is None:
        return -1
    a, b = parsed
    result = 1
    while len(b) > 1:
        m, n = len(a)-1, len(b)-1
        if m < n:
            if m*n & 1:
                result = -result % P
            a, b = b, a
            continue
        remainder = a[:]
        inverse = pow(b[-1], P-2, P)
        while len(remainder) >= len(b):
            shift = len(remainder)-len(b)
            factor = remainder[-1] * inverse % P
            for i, coefficient in enumerate(b):
                remainder[shift+i] = (remainder[shift+i] - factor*coefficient) % P
            while remainder and remainder[-1] == 0:
                remainder.pop()
        if not remainder:
            return 0
        r = len(remainder)-1
        result = result * pow(b[-1], m-r, P) % P
        if m*n & 1:
            result = -result % P
        a, b = b, remainder
    return result * pow(b[0], len(a)-1, P) % P
