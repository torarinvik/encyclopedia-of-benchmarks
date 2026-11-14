"""Newton-difference reference for polynomial discrete antidifferentiation."""
P = 998244353

def expected_output(values, capacity=None, output_is_null=False, input_is_null=False, input_length=None):
    if (input_is_null or not isinstance(values, (tuple, list)) or len(values) < 2
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)
            or (input_length is not None and (type(input_length) is not int or input_length != len(values)))
            or (capacity is not None and (type(capacity) is not int or capacity < 0))):
        return -1, b""
    n = values[0]
    if not 1 <= n <= 32 or len(values) != n+1 or any(x < 0 or x >= P for x in values[1:]):
        return -1, b""
    ys = [0]
    for x in range(n):
        value = 0
        for coefficient in reversed(values[1:]): value = (value*x+coefficient) % P
        ys.append((ys[-1]+value) % P)
    differences = ys[:]
    coeffs = [0]*(n+1)
    basis = [1]
    inv_factorial = 1
    for k in range(n+1):
        scale = differences[0]*inv_factorial % P
        for degree, coefficient in enumerate(basis):
            coeffs[degree] = (coeffs[degree]+scale*coefficient) % P
        differences = [(differences[i+1]-differences[i]) % P for i in range(len(differences)-1)]
        if k < n:
            next_basis = [0]*(len(basis)+1)
            for degree, coefficient in enumerate(basis):
                next_basis[degree] = (next_basis[degree]-k*coefficient) % P
                next_basis[degree+1] = (next_basis[degree+1]+coefficient) % P
            basis = next_basis
            inv_factorial = inv_factorial*pow(k+1,P-2,P) % P
    size = 8*(n+1)
    if output_is_null or (capacity is not None and capacity < size): return -2, b""
    return size, b"".join(x.to_bytes(8,"little",signed=True) for x in coeffs)
