"""Primary oracle for one bounded min-plus distance-matrix product."""

INF = 1_000_000
MAX_INPUT_LENGTH = 130
MAX_OUTPUT_BYTES = 512


def _parse(a):
    if a is None or len(a) < 4 or len(a) > MAX_INPUT_LENGTH:
        return None
    n, m = a[0], a[1]
    if not isinstance(n, int) or not 1 <= n <= 8 or not isinstance(m, int) or not 1 <= m <= 8:
        return None
    if len(a) != 2 + 2*n*m:
        return None
    entries = a[2:]
    if any(not isinstance(x, int) or (x < 0 or x > 1000 and x != INF) for x in entries):
        return None
    return n, m, entries[:n*m], entries[n*m:]


def evaluate(a):
    parsed = _parse(a)
    if parsed is None:
        return -1, b""
    n, m, left, right = parsed
    result = []
    for i in range(n):
        for j in range(n):
            best = INF
            for k in range(m):
                x = left[i*m+k]
                y = right[k*n+j]
                if x != INF and y != INF and x+y < best:
                    best = x+y
            result.append(best)
    raw = b"".join(x.to_bytes(8, "little", signed=True) for x in result)
    return len(raw), raw
