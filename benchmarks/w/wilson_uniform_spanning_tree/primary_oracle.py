"""Successor-pointer reference for a bounded Wilson spanning-tree trace."""

MAX_VERTICES = 8
MAX_EDGES = MAX_VERTICES * (MAX_VERTICES - 1) // 2
MAX_STEPS_PER_WALK = 64
MAX_DRAWS = MAX_STEPS_PER_WALK * (MAX_VERTICES - 1)
MAX_VALID_INPUT_WORDS = 4 + 2 * MAX_EDGES + MAX_DRAWS
MAX_PARSEABLE_INPUT_WORDS = MAX_VALID_INPUT_WORDS + 1
MAX_OUTPUT_BYTES = 16 * (MAX_VERTICES - 1)
WORKSPACE_BYTES = 2048


def _is_i64_word(value):
    return type(value) is int and -(1 << 63) <= value < (1 << 63)


def _connected(adjacency, root):
    seen = {root}
    pending = [root]
    while pending:
        vertex = pending.pop()
        for neighbor in adjacency[vertex]:
            if neighbor not in seen:
                seen.add(neighbor)
                pending.append(neighbor)
    return len(seen) == len(adjacency)


def _run_successor_walks(adjacency, root, draws):
    vertex_count = len(adjacency)
    in_tree = [False] * vertex_count
    in_tree[root] = True
    successor = [-1] * vertex_count
    cursor = 0

    for start in range(vertex_count):
        if in_tree[start]:
            continue
        current = start
        steps = 0
        while not in_tree[current]:
            if steps >= MAX_STEPS_PER_WALK or cursor >= len(draws):
                return None
            choice = draws[cursor]
            neighbors = adjacency[current]
            if choice >= len(neighbors):
                return None
            successor[current] = neighbors[choice]
            current = successor[current]
            cursor += 1
            steps += 1

        current = start
        while not in_tree[current]:
            in_tree[current] = True
            current = successor[current]

    if cursor != len(draws):
        return None
    return successor


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if input_length is not None and (
            type(input_length) is not int or input_length < 0):
        return -1, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    length = len(values)
    if not 4 <= length <= MAX_PARSEABLE_INPUT_WORDS:
        return -1, b""
    if input_length is not None and input_length != length:
        return -1, b""
    if any(not _is_i64_word(value) for value in values):
        return -1, b""

    vertex_count, edge_count, root = values[:3]
    if not 1 <= vertex_count <= MAX_VERTICES or not 0 <= edge_count <= MAX_EDGES:
        return -1, b""
    if not 0 <= root < vertex_count:
        return -1, b""
    draw_count_index = 3 + 2 * edge_count
    if length <= draw_count_index:
        return -1, b""
    draw_count = values[draw_count_index]
    max_draws = MAX_STEPS_PER_WALK * (vertex_count - 1)
    if not 0 <= draw_count <= max_draws:
        return -1, b""
    if length != draw_count_index + 1 + draw_count:
        return -1, b""

    adjacency = [[] for _ in range(vertex_count)]
    previous_edge = None
    for edge in range(edge_count):
        left = values[3 + 2 * edge]
        right = values[4 + 2 * edge]
        pair = (left, right)
        if not (0 <= left < right < vertex_count):
            return -1, b""
        if previous_edge is not None and pair <= previous_edge:
            return -1, b""
        previous_edge = pair
        adjacency[left].append(right)
        adjacency[right].append(left)

    if any(not 0 <= draw <= MAX_VERTICES - 2 for draw in values[draw_count_index + 1:]):
        return -1, b""
    if not _connected(adjacency, root):
        return -1, b""

    draws = values[draw_count_index + 1:]
    successor = _run_successor_walks(adjacency, root, draws)
    if successor is None:
        return -1, b""

    required = 16 * (vertex_count - 1)
    if (output_is_null and required > 0) or (capacity is not None and capacity < required):
        return -2, b""

    output = bytearray()
    for child in range(vertex_count):
        if child == root:
            continue
        output.extend(child.to_bytes(8, "little", signed=False))
        output.extend(successor[child].to_bytes(8, "little", signed=False))
    return required, bytes(output)
