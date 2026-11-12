"""Primary simple Lengauer-Tarjan oracle for root-relative immediate dominators."""

MAX_VERTICES = 63
MAX_EDGES = 2047
MAX_INPUT_LENGTH = 3 + 2 * MAX_EDGES
MAX_OUTPUT_BYTES = MAX_VERTICES
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2
UNREACHABLE = 255


def _parse(values, input_is_null, input_length):
    if (not isinstance(values, (list, tuple))
            or len(values) < 3 or len(values) > MAX_INPUT_LENGTH
            or type(input_is_null) is not bool or input_is_null
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    n, root, m = values[:3]
    if not 1 <= n <= MAX_VERTICES or not 0 <= root < n:
        return None
    if not 0 <= m <= MAX_EDGES or len(values) != 3 + 2 * m:
        return None
    successors = [[] for _ in range(n)]
    seen = [set() for _ in range(n)]
    for pos in range(3, len(values), 2):
        source, target = values[pos], values[pos + 1]
        if not 0 <= source < n or not 0 <= target < n:
            return None
        if target not in seen[source]:
            seen[source].add(target)
            successors[source].append(target)
    return n, root, successors


def _eval(vertex, ancestor, label, semi):
    if ancestor[vertex] == 0:
        return vertex
    pending = []
    current = vertex
    while ancestor[ancestor[current]] != 0:
        pending.append(current)
        current = ancestor[current]
    while pending:
        current = pending.pop()
        parent = ancestor[current]
        if semi[label[parent]] < semi[label[current]]:
            label[current] = label[parent]
        ancestor[current] = ancestor[parent]
    return label[vertex]


def _dominator_bytes(n, root, successors):
    dfs_number = [0] * n
    vertex_at = [0] * (n + 1)
    parent = [0] * (n + 1)
    dfs_count = 1
    dfs_number[root] = 1
    vertex_at[1] = root
    node_stack = [root]
    edge_stack = [0]
    while node_stack:
        current = node_stack[-1]
        offset = edge_stack[-1]
        if offset == len(successors[current]):
            node_stack.pop()
            edge_stack.pop()
            continue
        target = successors[current][offset]
        edge_stack[-1] = offset + 1
        if dfs_number[target] == 0:
            dfs_count += 1
            dfs_number[target] = dfs_count
            vertex_at[dfs_count] = target
            parent[dfs_count] = dfs_number[current]
            node_stack.append(target)
            edge_stack.append(0)

    predecessors = [[] for _ in range(dfs_count + 1)]
    for source in range(n):
        if dfs_number[source] == 0:
            continue
        for target in successors[source]:
            if dfs_number[target] != 0:
                predecessors[dfs_number[target]].append(dfs_number[source])

    semi = list(range(dfs_count + 1))
    ancestor = [0] * (dfs_count + 1)
    label = list(range(dfs_count + 1))
    immediate = [0] * (dfs_count + 1)
    buckets = [[] for _ in range(dfs_count + 1)]

    for vertex in range(dfs_count, 1, -1):
        for predecessor in predecessors[vertex]:
            representative = _eval(predecessor, ancestor, label, semi)
            if semi[representative] < semi[vertex]:
                semi[vertex] = semi[representative]
        buckets[semi[vertex]].append(vertex)
        ancestor[vertex] = parent[vertex]
        owner = parent[vertex]
        waiting = buckets[owner]
        buckets[owner] = []
        for member in waiting:
            representative = _eval(member, ancestor, label, semi)
            immediate[member] = (representative if semi[representative] < semi[member]
                                 else owner)

    for vertex in range(2, dfs_count + 1):
        if immediate[vertex] != semi[vertex]:
            immediate[vertex] = immediate[immediate[vertex]]

    output = [UNREACHABLE] * n
    output[root] = root
    for original in range(n):
        number = dfs_number[original]
        if number > 1:
            output[original] = vertex_at[immediate[number]]
    return bytes(output)


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (type(output_is_null) is not bool
            or (output_capacity is not None
                and (type(output_capacity) is not int or output_capacity < 0))):
        return INVALID_RESULT, b""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    n, root, successors = parsed
    encoded = _dominator_bytes(n, root, successors)
    if output_is_null or (output_capacity is not None and output_capacity < len(encoded)):
        return OUTPUT_ERROR, b""
    return len(encoded), encoded
