"""Independent vertex-removal oracle for immediate dominators."""

MAX_VERTICES = 63
MAX_EDGES = 2047
MAX_INPUT_LENGTH = 3 + 2 * MAX_EDGES
MAX_OUTPUT_BYTES = MAX_VERTICES
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
UNREACHABLE = 255


def _read(values, input_is_null, input_length):
    if (not isinstance(values, (list, tuple)) or input_is_null
            or len(values) < 3 or len(values) > MAX_INPUT_LENGTH
            or type(input_is_null) is not bool
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))):
        return None
    for value in values:
        if type(value) is not int or value < I64_MIN or value > I64_MAX:
            return None
    n, root, m = values[0], values[1], values[2]
    if not 1 <= n <= MAX_VERTICES or not 0 <= root < n or not 0 <= m <= MAX_EDGES:
        return None
    if len(values) != 3 + 2 * m:
        return None
    adjacency = [set() for _ in range(n)]
    for edge in range(m):
        source, target = values[3 + 2 * edge:5 + 2 * edge]
        if source < 0 or source >= n or target < 0 or target >= n:
            return None
        adjacency[source].add(target)
    return n, root, adjacency


def _reachable(adjacency, root, removed=-1):
    if root == removed:
        return set()
    reached = {root}
    queue = [root]
    cursor = 0
    while cursor < len(queue):
        vertex = queue[cursor]
        cursor += 1
        for target in adjacency[vertex]:
            if target != removed and target not in reached:
                reached.add(target)
                queue.append(target)
    return reached


def _direct_dominators(n, root, adjacency):
    reachable = _reachable(adjacency, root)
    dominates = [[False] * n for _ in range(n)]
    for vertex in reachable:
        dominates[root][vertex] = True
    for removed in reachable:
        if removed == root:
            continue
        without = _reachable(adjacency, root, removed)
        for vertex in reachable:
            dominates[removed][vertex] = vertex == removed or vertex not in without

    output = [UNREACHABLE] * n
    output[root] = root
    for target in reachable:
        if target == root:
            continue
        strict_dominators = [candidate for candidate in reachable
                             if candidate != target and dominates[candidate][target]]
        nearest = [candidate for candidate in strict_dominators
                   if all(other == candidate or dominates[other][candidate]
                          for other in strict_dominators)]
        if len(nearest) != 1:
            return None
        output[target] = nearest[0]
    return bytes(output)


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (type(output_is_null) is not bool
            or (output_capacity is not None
                and (type(output_capacity) is not int or output_capacity < 0))):
        return -1, b""
    parsed = _read(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    n, root, adjacency = parsed
    encoded = _direct_dominators(n, root, adjacency)
    if encoded is None:
        return -1, b""
    if output_is_null or (output_capacity is not None and output_capacity < len(encoded)):
        return -2, b""
    return len(encoded), encoded
