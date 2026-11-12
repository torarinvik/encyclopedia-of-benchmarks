"""Primary bounded Stoer-Wagner recomputation oracle for dynamic star updates."""

MAX_N = 16
MAX_M = 64
MAX_Q = 32
MAX_WEIGHT = 1_000_000
MAX_VALID_INPUT_LENGTH = 3 + MAX_N + 3 * MAX_M + 2 * MAX_Q
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = MAX_Q
MAX_OUTPUT_BYTES = 8 * MAX_Q
MAX_WORKSPACE_BYTES = MAX_OUTPUT_BYTES


def _parse(values):
    if values is None or len(values) < 3 or len(values) > MAX_INPUT_LENGTH:
        return None
    n, m, q = values[:3]
    if (type(n) is not int or not 1 <= n <= MAX_N
            or type(m) is not int or not 0 <= m <= min(n * (n - 1) // 2, MAX_M)
            or type(q) is not int or not 1 <= q <= MAX_Q):
        return None
    expected = 3 + n + 3 * m + 2 * q
    if len(values) != expected:
        return None
    pos = 3
    spokes = values[pos:pos + n]
    pos += n
    if any(type(w) is not int or not 0 <= w <= MAX_WEIGHT for w in spokes):
        return None
    edges = []
    seen = set()
    for _ in range(m):
        u, v, weight = values[pos:pos + 3]
        pos += 3
        if (type(u) is not int or type(v) is not int or type(weight) is not int
                or not 0 <= u < n or not 0 <= v < n or u == v
                or not 0 <= weight <= MAX_WEIGHT):
            return None
        key = (min(u, v), max(u, v))
        if key in seen:
            return None
        seen.add(key)
        edges.append((u, v, weight))
    updates = []
    for _ in range(q):
        x, y = values[pos:pos + 2]
        pos += 2
        if (type(x) is not int or type(y) is not int
                or not 0 <= x < n or not 0 <= y <= MAX_WEIGHT):
            return None
        updates.append((x, y))
    return n, spokes, edges, updates


def _stoer_wagner(n, spokes, edges):
    size = n + 1
    matrix = [[0] * size for _ in range(size)]
    for u, v, weight in edges:
        matrix[u][v] += weight
        matrix[v][u] += weight
    supernode = n
    for vertex, weight in enumerate(spokes):
        matrix[vertex][supernode] += weight
        matrix[supernode][vertex] += weight
    active = list(range(size))
    best = None
    while len(active) > 1:
        used = [False] * size
        connection = [0] * size
        previous = -1
        for step in range(len(active)):
            selected = -1
            for vertex in active:
                if not used[vertex] and (selected < 0 or connection[vertex] > connection[selected]
                                         or connection[vertex] == connection[selected] and vertex < selected):
                    selected = vertex
            if step + 1 == len(active):
                cut = connection[selected]
                if best is None or cut < best:
                    best = cut
                for vertex in active:
                    if vertex != selected and vertex != previous:
                        matrix[previous][vertex] += matrix[selected][vertex]
                        matrix[vertex][previous] = matrix[previous][vertex]
                active.remove(selected)
                break
            used[selected] = True
            previous = selected
            for vertex in active:
                if not used[vertex]:
                    connection[vertex] += matrix[selected][vertex]
    return 0 if best is None else best


def evaluate(values):
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    n, spokes, edges, updates = parsed
    answers = []
    for vertex, weight in updates:
        spokes[vertex] = weight
        answers.append(_stoer_wagner(n, spokes, edges))
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
