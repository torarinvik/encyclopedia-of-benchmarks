"""Primary direct-definition oracle for bounded modular subset convolution."""

MODULUS = 998_244_353
MAX_N = 4
MAX_INPUT_LENGTH = 33
MAX_OUTPUT_BYTES = 128


def evaluate(values):
    if values is None or len(values) < 3 or len(values) > MAX_INPUT_LENGTH:
        return -1, b""
    n = values[0]
    if not 0 <= n <= MAX_N:
        return -1, b""
    size = 1 << n
    if len(values) != 1 + 2 * size:
        return -1, b""
    f = values[1:1+size]
    g = values[1+size:1+2*size]
    if any(x < 0 or x >= MODULUS for x in f + g):
        return -1, b""
    result = []
    for mask in range(size):
        total = 0
        sub = mask
        while True:
            total = (total + f[sub] * g[mask ^ sub]) % MODULUS
            if sub == 0:
                break
            sub = (sub - 1) & mask
        result.append(total)
    raw = b"".join(x.to_bytes(8, "little", signed=True) for x in result)
    return len(raw), raw
