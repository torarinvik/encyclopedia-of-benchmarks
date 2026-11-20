"""Per-target absorbing-chain systems; deliberately separate from primary."""

import struct

FIELD = 1_000_000_007
N_LIMIT = 8
MAX_PARSEABLE_INPUT_LENGTH = 2 + 2 * N_LIMIT * (N_LIMIT - 1) + 1
MAX_OUTPUT_BYTES = 8 * N_LIMIT * N_LIMIT
WORKSPACE_BYTES = 8192


def _inverse(number):
    return pow(number % FIELD, FIELD - 2, FIELD)


def _graph(frame):
    if not isinstance(frame, (list, tuple)) or len(frame) < 2:
        return None
    if any(type(item) is not int or item < -(1 << 63) or item >= 1 << 63 for item in frame):
        return None
    n, m = frame[0], frame[1]
    if not 3 <= n <= N_LIMIT or not 0 <= m <= n * (n - 1):
        return None
    if len(frame) != 2 + 2 * m:
        return None
    outgoing = [set() for _ in range(n)]
    incoming = [set() for _ in range(n)]
    for index in range(m):
        source, destination = frame[2 + 2 * index:4 + 2 * index]
        if not 0 <= source < n or not 0 <= destination < n or source == destination:
            return None
        if destination in outgoing[source]:
            return None
        outgoing[source].add(destination)
        incoming[destination].add(source)
    if any(not row for row in outgoing):
        return None
    for graph in (outgoing, incoming):
        reached = [False] * n
        reached[0] = True
        frontier = [0]
        for vertex in frontier:
            for neighbor in graph[vertex]:
                if not reached[neighbor]:
                    reached[neighbor] = True
                    frontier.append(neighbor)
        if not all(reached):
            return None
    return n, outgoing


def _linear_solve(augmented, size):
    for pivot_column in range(size):
        pivot_row = pivot_column
        while pivot_row < size and augmented[pivot_row][pivot_column] % FIELD == 0:
            pivot_row += 1
        if pivot_row == size:
            raise ValueError("absorbing system must be invertible for a strongly connected graph")
        augmented[pivot_column], augmented[pivot_row] = augmented[pivot_row], augmented[pivot_column]
        inverse = _inverse(augmented[pivot_column][pivot_column])
        for column in range(pivot_column, size + 1):
            augmented[pivot_column][column] = augmented[pivot_column][column] * inverse % FIELD
        for row in range(size):
            if row == pivot_column:
                continue
            factor = augmented[row][pivot_column] % FIELD
            for column in range(pivot_column, size + 1):
                augmented[row][column] = (augmented[row][column]
                                          - factor * augmented[pivot_column][column]) % FIELD
    return [augmented[row][size] for row in range(size)]


def evaluate(frame):
    parsed = _graph(frame)
    if parsed is None:
        return -1, b""
    n, outgoing = parsed
    result = [[0] * n for _ in range(n)]
    for target in range(n):
        sources = [vertex for vertex in range(n) if vertex != target]
        slot = {vertex: index for index, vertex in enumerate(sources)}
        system = [[0] * (n) for _ in sources]
        for row, source in enumerate(sources):
            degree = len(outgoing[source])
            system[row][row] = degree
            for neighbor in outgoing[source]:
                if neighbor != target:
                    system[row][slot[neighbor]] -= 1
            system[row][-1] = degree
        values = _linear_solve(system, n - 1)
        for source, row in slot.items():
            result[source][target] = values[row]
    payload = b"".join(struct.pack("<q", result[source][target])
                       for source in range(n) for target in range(n))
    return len(payload), payload


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < 0)
            or input_length is not None
            and (type(input_length) is not int
                 or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    try:
        actual_length = len(values)
    except TypeError:
        return -1, b""
    if input_length is not None and input_length != actual_length:
        return -1, b""
    if actual_length > MAX_PARSEABLE_INPUT_LENGTH:
        return -1, b""
    result, payload = evaluate(values)
    if result < 0:
        return result, payload
    if output_is_null or output_capacity is not None and output_capacity < result:
        return -2, b""
    return result, payload
