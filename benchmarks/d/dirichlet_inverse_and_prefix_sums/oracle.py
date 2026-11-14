"""Coefficient-level reference for bounded Dirichlet inverse prefixes."""
P = 998244353

def expected_output(values, capacity=None, output_is_null=False, input_is_null=False, input_length=None):
    if (input_is_null or not isinstance(values, (tuple, list)) or len(values) < 2
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)
            or (input_length is not None and (type(input_length) is not int or input_length != len(values)))
            or (capacity is not None and (type(capacity) is not int or capacity < 0))):
        return -1, b""
    n = values[0]
    if not 1 <= n <= 64: return -1, b""
    quotients = sorted({n//i for i in range(1,n+1)})
    if len(values) != 1+len(quotients) or any(x < 0 or x >= P for x in values[1:]) or values[1] == 0:
        return -1, b""
    f = [0]*(n+1)
    previous = 0
    for x, prefix in zip(quotients, values[1:]):
        f[x] = (prefix-previous) % P
        previous = prefix
    inv = pow(f[1], P-2, P)
    g = [0]*(n+1)
    g[1] = inv
    for x in range(2,n+1):
        g[x] = -inv*sum(f[d]*g[x//d] for d in range(2,x+1) if x%d == 0) % P
    prefix = [0]*(n+1)
    for x in range(1,n+1): prefix[x] = (prefix[x-1]+g[x]) % P
    size = 8*len(quotients)
    if output_is_null or (capacity is not None and capacity < size): return -2, b""
    return size, b"".join(prefix[x].to_bytes(8,"little",signed=True) for x in quotients)
