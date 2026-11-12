"""Independent exhaustive-cut verifier for bounded dynamic star min-cuts."""

MAX_N = 16
MAX_M = 64
MAX_Q = 32
MAX_WEIGHT = 1_000_000
MAX_INPUT_LENGTH = 3 + MAX_N + 3 * MAX_M + 2 * MAX_Q + 1
MAX_OUTPUT_ELEMENTS = MAX_Q
MAX_OUTPUT_BYTES = 8 * MAX_Q


def _decode(values):
    if values is None or len(values) < 3 or len(values) > MAX_INPUT_LENGTH:
        return None
    n, m, q = values[:3]
    if (type(n) is not int or n < 1 or n > MAX_N or type(m) is not int
            or m < 0 or m > min(n * (n - 1) // 2, MAX_M)
            or type(q) is not int or q < 1 or q > MAX_Q):
        return None
    if len(values) != 3 + n + 3 * m + 2 * q:
        return None
    pos = 3
    spokes = list(values[pos:pos + n]); pos += n
    if any(type(x) is not int or x < 0 or x > MAX_WEIGHT for x in spokes):
        return None
    edges = []
    used = set()
    for _ in range(m):
        u, v, w = values[pos:pos + 3]; pos += 3
        if (type(u) is not int or type(v) is not int or type(w) is not int
                or not 0 <= u < n or not 0 <= v < n or u == v or not 0 <= w <= MAX_WEIGHT):
            return None
        edge = (min(u, v), max(u, v))
        if edge in used:
            return None
        used.add(edge); edges.append((u, v, w))
    updates = []
    for _ in range(q):
        x, y = values[pos:pos + 2]; pos += 2
        if type(x) is not int or type(y) is not int or not 0 <= x < n or not 0 <= y <= MAX_WEIGHT:
            return None
        updates.append((x, y))
    return n, spokes, edges, updates


def _cut_table(n, edges):
    count = 1 << n
    crossing = [0] * count
    for mask in range(1, count):
        total = 0
        for u, v, w in edges:
            if ((mask >> u) ^ (mask >> v)) & 1:
                total += w
        crossing[mask] = total
    return crossing


def evaluate(values):
    parsed = _decode(values)
    if parsed is None:
        return -1, b""
    n, spokes, edges, updates = parsed
    crossing = _cut_table(n, edges)
    answers = []
    for vertex, weight in updates:
        spokes[vertex] = weight
        spoke_cut = [0] * (1 << n)
        for mask in range(1, 1 << n):
            bit = mask & -mask
            index = bit.bit_length() - 1
            spoke_cut[mask] = spoke_cut[mask ^ bit] + spokes[index]
        best = None
        for mask in range(1, 1 << n):
            cut = crossing[mask] + spoke_cut[mask]
            if best is None or cut < best:
                best = cut
        answers.append(0 if best is None else best)
    raw = b"".join(x.to_bytes(8, "little", signed=True) for x in answers)
    return len(raw), raw


def expected_output(values, capacity=None, output_is_null=False, input_is_null=False,
                    input_length=None):
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    try:
        actual_length = len(values)
    except TypeError:
        return -1, b""
    if input_length is not None and input_length != actual_length:
        return -1, b""
    written, raw = evaluate(values)
    if written < 0:
        return written, raw
    if output_is_null or capacity is not None and capacity < written:
        return -2, b""
    return written, raw
