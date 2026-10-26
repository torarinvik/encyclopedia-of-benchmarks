"""Independent last-accepted-position verifier for the edge reservoir."""

MAX_INPUT_LENGTH = 114
MAX_OUTPUT_BYTES = 448


def verify(a):
    if a is None or len(a) < 6 or len(a) > 114:
        return -1, b""
    n, m = a[0], a[1]
    if not isinstance(n, int) or n < 2 or n > 8 or not isinstance(m, int) or m < 1 or m > 28:
        return -1, b""
    if len(a) != 2 + 4*m:
        return -1, b""
    edges = []
    seen = set()
    for i in range(m):
        e = (a[2+2*i], a[3+2*i])
        if not all(isinstance(x, int) for x in e) or not 0 <= e[0] < e[1] < n or e in seen:
            return -1, b""
        seen.add(e)
        edges.append(e)
    draws = a[2+2*m:]
    for t in range(1, m+1):
        if any(not isinstance(draws[2*(t-1)+s], int) or not 0 <= draws[2*(t-1)+s] < t for s in range(2)):
            return -1, b""
    output = []
    for t in range(1, m+1):
        for slot in range(2):
            accepted = [i for i in range(t) if draws[2*i+slot] == 0]
            edge = edges[accepted[-1]]
            output.extend(edge)
    raw = b"".join(int(x).to_bytes(8, "little", signed=True) for x in output)
    return len(raw), raw
