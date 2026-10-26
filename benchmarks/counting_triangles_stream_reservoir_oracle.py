"""Primary oracle for the bounded uniform-edge reservoir profile."""

MAX_INPUT_LENGTH = 114
MAX_OUTPUT_BYTES = 448


def _parse(a):
    if a is None or len(a) < 6 or len(a) > MAX_INPUT_LENGTH:
        return None
    n, m = a[0], a[1]
    if not isinstance(n, int) or not 2 <= n <= 8 or not isinstance(m, int) or not 1 <= m <= 28:
        return None
    if len(a) != 2 + 4*m:
        return None
    edges = [tuple(a[2+2*i:4+2*i]) for i in range(m)]
    seen = set()
    for u, v in edges:
        if not isinstance(u, int) or not isinstance(v, int) or not 0 <= u < v < n or (u,v) in seen:
            return None
        seen.add((u,v))
    draws = a[2+2*m:]
    for t in range(1,m+1):
        for slot in range(2):
            value = draws[2*(t-1)+slot]
            if not isinstance(value, int) or not 0 <= value < t:
                return None
    return n, m, edges, draws


def evaluate(a):
    parsed = _parse(a)
    if parsed is None:
        return -1, b""
    _, m, edges, draws = parsed
    slots = [None, None]
    output = []
    for t, edge in enumerate(edges, 1):
        for slot in range(2):
            if draws[2*(t-1)+slot] == 0:
                slots[slot] = edge
        for item in slots:
            output.extend(item)
    raw = b"".join(int(x).to_bytes(8, "little", signed=True) for x in output)
    return len(raw), raw
