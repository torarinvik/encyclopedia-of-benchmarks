"""Newton-refinement reference for bounded bivariate series inversion."""
P = 998244353

def expected_output(values, capacity=None, output_is_null=False, input_is_null=False, input_length=None):
    if (input_is_null or not isinstance(values, (list, tuple)) or len(values) < 3
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)
            or (input_length is not None and (type(input_length) is not int or input_length != len(values)))
            or (capacity is not None and (type(capacity) is not int or capacity < 0))):
        return -1, b""
    n, m = values[:2]
    if not (1 <= n <= 8 and 1 <= m <= 8 and len(values) == 2+n*m): return -1, b""
    f = list(values[2:])
    if not f[0] or any(x < 0 or x >= P for x in f): return -1, b""
    def multiply(a, b):
        result = [0]*(n*m)
        for i in range(n):
            for j in range(m):
                for k in range(n-i):
                    for l in range(m-j):
                        index = (i+k)*m+j+l
                        result[index] = (result[index]+a[i*m+j]*b[k*m+l]) % P
        return result
    g = [0]*(n*m)
    g[0] = pow(f[0],P-2,P)
    for _ in range(4):
        product = multiply(f,g)
        correction = [(-v) % P for v in product]
        correction[0] = (correction[0]+2) % P
        g = multiply(g,correction)
    size = 8*n*m
    if output_is_null or (capacity is not None and capacity < size): return -2, b""
    return size, b"".join(x.to_bytes(8,"little",signed=True) for x in g)
