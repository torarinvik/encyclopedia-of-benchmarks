"""Power-series reference for a bounded square-zero set logarithm."""
P = 998244353

def expected_output(values, capacity=None, output_is_null=False, input_is_null=False, input_length=None):
    if (input_is_null or not isinstance(values, (list, tuple)) or len(values) < 2
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)
            or (input_length is not None and (type(input_length) is not int or input_length != len(values)))
            or (capacity is not None and (type(capacity) is not int or capacity < 0))):
        return -1, b""
    n = values[0]
    if not 0 <= n <= 5 or len(values) != 1+(1 << n): return -1, b""
    f = list(values[1:])
    if f[0] != 1 or any(x < 0 or x >= P for x in f): return -1, b""
    size = 1 << n
    x = [0]+f[1:]
    power = [0]*size
    power[0] = 1
    result = [0]*size
    for k in range(1,n+1):
        next_power = [0]*size
        for mask in range(size):
            sub = mask
            while True:
                next_power[mask] = (next_power[mask]+power[mask^sub]*x[sub]) % P
                if sub == 0: break
                sub = (sub-1)&mask
        power = next_power
        factor = pow(k,P-2,P)
        if k%2 == 0: factor = -factor
        for mask in range(size): result[mask] = (result[mask]+factor*power[mask]) % P
    if output_is_null or (capacity is not None and capacity < 8*size): return -2, b""
    return 8*size, b"".join(v.to_bytes(8,"little",signed=True) for v in result)
