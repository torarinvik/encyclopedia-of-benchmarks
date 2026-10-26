"""Independent rank-transform verifier for fast subset convolution."""

P = 998_244_353


def verify(values):
    if values is None or len(values) < 3:
        return -1, b""
    n = values[0]
    if n < 0 or n > 4:
        return -1, b""
    size = 1 << n
    if len(values) != 1 + 2 * size:
        return -1, b""
    left = list(values[1:1+size])
    right = list(values[1+size:])
    if any(v < 0 or v >= P for v in left + right):
        return -1, b""
    f = [[0] * size for _ in range(n+1)]
    g = [[0] * size for _ in range(n+1)]
    for mask in range(size):
        rank = mask.bit_count()
        f[rank][mask] = left[mask]
        g[rank][mask] = right[mask]
    for bit in range(n):
        flag = 1 << bit
        for mask in range(size):
            if mask & flag:
                other = mask ^ flag
                for rank in range(n+1):
                    f[rank][mask] = (f[rank][mask] + f[rank][other]) % P
                    g[rank][mask] = (g[rank][mask] + g[rank][other]) % P
    h = [[0] * size for _ in range(n+1)]
    for mask in range(size):
        for rank in range(n+1):
            acc = 0
            for i in range(rank+1):
                acc += f[i][mask] * g[rank-i][mask]
            h[rank][mask] = acc % P
    for bit in range(n):
        flag = 1 << bit
        for mask in range(size):
            if mask & flag:
                other = mask ^ flag
                for rank in range(n+1):
                    h[rank][mask] = (h[rank][mask] - h[rank][other]) % P
    output = [h[mask.bit_count()][mask] for mask in range(size)]
    raw = b"".join(x.to_bytes(8, "little", signed=True) for x in output)
    return len(raw), raw
