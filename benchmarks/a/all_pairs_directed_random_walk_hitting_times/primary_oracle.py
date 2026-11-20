"""Stationary-distribution and rank-deficient-system reference."""

import struct

MOD = 1_000_000_007
MAX_N = 8
MAX_M = MAX_N * (MAX_N - 1)
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_M
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * MAX_N * MAX_N
WORKSPACE_BYTES = 8192


def _mod_inverse(value):
    return pow(value % MOD, MOD - 2, MOD)


def _parse(values, input_is_null=False, input_length=None):
    if type(input_is_null) is not bool or input_is_null:
        return None
    if not isinstance(values, (list, tuple)):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values) or input_length < 2
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n_value, m_value = values[0], values[1]
    if not 3 <= n_value <= MAX_N or not 0 <= m_value <= n_value * (n_value - 1):
        return None
    n, m = n_value, m_value
    if len(values) != 2 + 2 * m:
        return None
    adjacency = [[False] * n for _ in range(n)]
    reverse = [[False] * n for _ in range(n)]
    degree = [0] * n
    for edge in range(m):
        u, v = values[2 + 2 * edge:4 + 2 * edge]
        if not 0 <= u < n or not 0 <= v < n or u == v or adjacency[u][v]:
            return None
        adjacency[u][v] = True
        reverse[v][u] = True
        degree[u] += 1
    if any(value == 0 for value in degree):
        return None

    def reaches_all(graph):
        seen = {0}
        queue = [0]
        for vertex in queue:
            for neighbor, present in enumerate(graph[vertex]):
                if present and neighbor not in seen:
                    seen.add(neighbor)
                    queue.append(neighbor)
        return len(seen) == n

    if not reaches_all(adjacency) or not reaches_all(reverse):
        return None
    return n, adjacency, degree


def _solve_all_right_sides(matrix, size, rhs_count):
    """Gauss-Jordan elimination over MOD; matrix has size+rhs_count columns."""
    for column in range(size):
        pivot = next((row for row in range(column, size)
                      if matrix[row][column] % MOD), None)
        if pivot is None:
            raise ValueError("the pinned strongly connected profile must be nonsingular")
        matrix[column], matrix[pivot] = matrix[pivot], matrix[column]
        scale = _mod_inverse(matrix[column][column])
        matrix[column] = [(value * scale) % MOD for value in matrix[column]]
        for row in range(size):
            if row == column:
                continue
            factor = matrix[row][column] % MOD
            if factor:
                matrix[row] = [(left - factor * right) % MOD
                               for left, right in zip(matrix[row], matrix[column])]
    return [row[size:size + rhs_count] for row in matrix]


def evaluate(values, input_is_null=False, input_length=None):
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    n, adjacency, degree = parsed

    # Solve pi*P=pi, replacing the final balance equation by sum(pi)=1.
    stationary = [[0] * (n + 1) for _ in range(n)]
    for destination in range(n - 1):
        for source in range(n):
            transition = _mod_inverse(degree[source]) if adjacency[source][destination] else 0
            stationary[destination][source] = (transition - (source == destination)) % MOD
    stationary[n - 1][:n] = [1] * n
    stationary[n - 1][n] = 1
    solved_stationary = _solve_all_right_sides(stationary, n, 1)
    pi = [solved_stationary[row][0] for row in range(n)]
    if any(value == 0 for value in pi):
        raise ValueError("strong connectivity implies positive stationary mass")
    reciprocal = [_mod_inverse(value) for value in pi]

    # Fix the final coordinate of each column to zero and solve the first n-1
    # independent rows of (I-P)Y = J-diag(1/pi).
    reduced = [[0] * (n - 1 + n) for _ in range(n - 1)]
    for row in range(n - 1):
        for column in range(n - 1):
            transition = _mod_inverse(degree[row]) if adjacency[row][column] else 0
            reduced[row][column] = ((row == column) - transition) % MOD
        for target in range(n):
            reduced[row][n - 1 + target] = (1 - (reciprocal[target] if row == target else 0)) % MOD
    solved = _solve_all_right_sides(reduced, n - 1, n)
    y = [[0] * n for _ in range(n)]
    for row in range(n - 1):
        y[row] = solved[row]

    answer = [[(y[source][target] - y[target][target]) % MOD
               for target in range(n)] for source in range(n)]
    payload = b"".join(struct.pack("<q", answer[source][target])
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
    result, payload = evaluate(values, False, actual_length)
    if result < 0:
        return result, payload
    if output_is_null or output_capacity is not None and output_capacity < result:
        return -2, b""
    return result, payload
