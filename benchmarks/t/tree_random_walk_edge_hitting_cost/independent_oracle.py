"""Exact first-step-equation oracle using rational Gaussian elimination."""

from fractions import Fraction
import struct

MAX_N = 16
MAX_INPUT_LENGTH = 2 + 3 * (MAX_N - 1) + 1
MAX_VALID_INPUT_LENGTH = MAX_INPUT_LENGTH - 1
MAX_OUTPUT_BYTES = 2 * (MAX_N - 1) * 8
MAX_WORKSPACE_BYTES = 16384


def _parse(values):
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, root = values[0], values[1]
    if not 1 <= n <= MAX_N or not 0 <= root < n:
        return None
    if len(values) != 2 + 3 * (n - 1):
        return None
    graph = [[] for _ in range(n)]
    edges = []
    components = list(range(n))

    def representative(vertex):
        while components[vertex] != vertex:
            components[vertex] = components[components[vertex]]
            vertex = components[vertex]
        return vertex

    offset = 2
    for _ in range(n - 1):
        u, v, weight = values[offset:offset + 3]
        offset += 3
        if not 0 <= u < n or not 0 <= v < n or u == v or not 1 <= weight <= 9:
            return None
        ru, rv = representative(u), representative(v)
        if ru == rv:
            return None
        components[ru] = rv
        graph[u].append((v, weight))
        graph[v].append((u, weight))
        edges.append((u, v, weight))
    return n, root, graph, edges


def _solve_for_target(n, graph, target):
    vertices = [vertex for vertex in range(n) if vertex != target]
    index = {vertex: position for position, vertex in enumerate(vertices)}
    matrix = []
    for vertex in vertices:
        degree = len(graph[vertex])
        row = [Fraction(0) for _ in range(len(vertices) + 1)]
        row[index[vertex]] = Fraction(1)
        for neighbor, _weight in graph[vertex]:
            if neighbor != target:
                row[index[neighbor]] -= Fraction(1, degree)
        row[-1] = Fraction(sum(weight for _, weight in graph[vertex]), degree)
        matrix.append(row)

    size = len(vertices)
    for column in range(size):
        pivot = next((row for row in range(column, size)
                      if matrix[row][column] != 0), None)
        if pivot is None:
            raise ValueError("hitting-time system is singular for a tree target")
        matrix[column], matrix[pivot] = matrix[pivot], matrix[column]
        divisor = matrix[column][column]
        matrix[column] = [value / divisor for value in matrix[column]]
        for row in range(size):
            if row == column:
                continue
            factor = matrix[row][column]
            if factor:
                matrix[row] = [left - factor * right
                               for left, right in zip(matrix[row], matrix[column])]
    result = [Fraction(0) for _ in range(n)]
    for vertex, row in index.items():
        result[vertex] = matrix[row][-1]
    return result


def evaluate(values):
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    n, _root, graph, edges = parsed
    targets = {}
    answers = []
    for u, v, _weight in edges:
        if v not in targets:
            targets[v] = _solve_for_target(n, graph, v)
        if u not in targets:
            targets[u] = _solve_for_target(n, graph, u)
        toward_v = targets[v][u]
        toward_u = targets[u][v]
        if toward_v.denominator != 1 or toward_u.denominator != 1:
            raise ValueError("weighted-tree hitting costs should be integral")
        answers.extend((toward_v.numerator, toward_u.numerator))
    payload = b"".join(struct.pack("<q", answer) for answer in answers)
    return len(payload), payload


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < 0)
            or input_length is not None
            and (type(input_length) is not int
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
    result, payload = evaluate(values)
    if result < 0:
        return result, payload
    if output_is_null or output_capacity is not None and output_capacity < result:
        return -2, b""
    return result, payload
