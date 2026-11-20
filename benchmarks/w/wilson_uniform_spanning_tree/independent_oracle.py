"""Buffered-walk reference with post-hoc chronological loop erasure."""

VERTEX_LIMIT = 8
EDGE_LIMIT = 28
WALK_LIMIT = 64
TAPE_LIMIT = (VERTEX_LIMIT - 1) * WALK_LIMIT
VALID_WORD_LIMIT = 4 + 2 * EDGE_LIMIT + TAPE_LIMIT
FRAME_LIMIT = VALID_WORD_LIMIT + 1
OUTPUT_LIMIT = 16 * (VERTEX_LIMIT - 1)
WORKSPACE_BYTES = 2048
I64_MIN = -(1 << 63)
I64_END = 1 << 63


def _valid_i64(value):
    return type(value) is int and I64_MIN <= value < I64_END


def _connected_by_closure(graph):
    size = len(graph)
    reach = [[False] * size for _ in range(size)]
    for source in range(size):
        reach[source][source] = True
        for target in graph[source]:
            reach[source][target] = True
    for middle in range(size):
        for source in range(size):
            if not reach[source][middle]:
                continue
            for target in range(size):
                reach[source][target] = reach[source][target] or reach[middle][target]
    return all(reach[0])


def _erase_after_walk(walk, root_tree):
    path = [walk[0]]
    while path[-1] not in root_tree:
        last_visit = -1
        tail = path[-1]
        for index, vertex in enumerate(walk):
            if vertex == tail:
                last_visit = index
        if last_visit < 0 or last_visit + 1 >= len(walk):
            return None
        path.append(walk[last_visit + 1])
    return path


def _construct_by_buffered_walks(graph, root, tape):
    size = len(graph)
    tree = {root}
    parents = [-1] * size
    cursor = 0
    for start in range(size):
        if start in tree:
            continue
        walk = [start]
        current = start
        steps = 0
        while current not in tree:
            if steps >= WALK_LIMIT or cursor >= len(tape):
                return None
            rank = tape[cursor]
            neighbors = graph[current]
            if rank >= len(neighbors):
                return None
            current = neighbors[rank]
            walk.append(current)
            cursor += 1
            steps += 1

        path = _erase_after_walk(walk, tree)
        if path is None or path[-1] not in tree:
            return None
        for index in range(len(path) - 1):
            child = path[index]
            parent = path[index + 1]
            parents[child] = parent
            tree.add(child)

    if cursor != len(tape):
        return None
    return parents


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    # Validation is local to this oracle and independent of the pointer model.
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if input_length is not None and (
            type(input_length) is not int or input_length < 0):
        return -1, b""
    if input_is_null or not isinstance(values, (tuple, list)):
        return -1, b""
    word_count = len(values)
    if word_count < 4 or word_count > FRAME_LIMIT:
        return -1, b""
    if input_length is not None and input_length != word_count:
        return -1, b""
    if any(not _valid_i64(word) for word in values):
        return -1, b""

    size = values[0]
    edge_total = values[1]
    root = values[2]
    if size < 1 or size > VERTEX_LIMIT or edge_total < 0 or edge_total > EDGE_LIMIT:
        return -1, b""
    if root < 0 or root >= size:
        return -1, b""
    tape_count_at = 3 + 2 * edge_total
    if word_count <= tape_count_at:
        return -1, b""
    tape_count = values[tape_count_at]
    if tape_count < 0 or tape_count > WALK_LIMIT * (size - 1):
        return -1, b""
    if word_count != tape_count_at + 1 + tape_count:
        return -1, b""

    graph = [[] for _ in range(size)]
    edge_pairs = []
    for edge_number in range(edge_total):
        left = values[3 + 2 * edge_number]
        right = values[4 + 2 * edge_number]
        if left < 0 or left >= right or right >= size:
            return -1, b""
        edge_pairs.append((left, right))
        graph[left].append(right)
        graph[right].append(left)
    if any(edge_pairs[index - 1] >= edge_pairs[index] for index in range(1, len(edge_pairs))):
        return -1, b""
    for neighbors in graph:
        neighbors.sort()

    tape = list(values[tape_count_at + 1:])
    if any(rank < 0 or rank >= VERTEX_LIMIT - 1 for rank in tape):
        return -1, b""
    if not _connected_by_closure(graph):
        return -1, b""
    parents = _construct_by_buffered_walks(graph, root, tape)
    if parents is None:
        return -1, b""

    required = 16 * (size - 1)
    if ((output_is_null and required > 0)
            or (capacity is not None and capacity < required)):
        return -2, b""
    encoded = bytearray()
    for child in range(size):
        if child == root:
            continue
        encoded.extend(child.to_bytes(8, "little", signed=False))
        encoded.extend(parents[child].to_bytes(8, "little", signed=False))
    return required, bytes(encoded)
