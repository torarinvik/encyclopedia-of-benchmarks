"""Oracle for TheAlgorithms/Python's bounded adjacency-matrix graph ADT trace."""

from __future__ import annotations

import struct

MAX_VERTICES = 8
MAX_VERTEX_ID_EXCLUSIVE = 32
MAX_EDGES = 64
MAX_OPERATIONS = 24
MAX_INPUT_LENGTH = 4 + MAX_VERTICES + 2 * MAX_EDGES + 3 * MAX_OPERATIONS
MAX_OUTPUT_BYTES = (2 + MAX_OPERATIONS + MAX_VERTICES + MAX_VERTICES * MAX_VERTICES) * 8


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple)) or len(values) < 4
            or any(type(value) is not int for value in values)):
        return -1, b""
    directed, vertex_count = values[:2]
    if directed not in (0, 1) or not 0 <= vertex_count <= MAX_VERTICES:
        return -1, b""
    if len(values) < 3 + vertex_count:
        return -1, b""
    vertices = list(values[2:2 + vertex_count])
    if (len(set(vertices)) != vertex_count
            or any(not 0 <= vertex < MAX_VERTEX_ID_EXCLUSIVE for vertex in vertices)):
        return -1, b""
    matrix = [[0] * MAX_VERTICES for _ in range(MAX_VERTICES)]
    index = 2 + vertex_count
    edge_count = values[index]
    index += 1
    if not 0 <= edge_count <= MAX_EDGES or len(values) < index + 2 * edge_count + 1:
        return -1, b""

    def vertex_index(vertex: int) -> int:
        try:
            return vertices.index(vertex)
        except ValueError:
            return -1

    for _ in range(edge_count):
        source, destination = values[index:index + 2]
        index += 2
        source_index = vertex_index(source)
        destination_index = vertex_index(destination)
        if source_index < 0 or destination_index < 0 or matrix[source_index][destination_index]:
            return -1, b""
        matrix[source_index][destination_index] = 1
        if not directed:
            matrix[destination_index][source_index] = 1

    operation_count = values[index]
    index += 1
    if (not 0 <= operation_count <= MAX_OPERATIONS
            or len(values) != index + 3 * operation_count):
        return -1, b""
    results: list[int] = []
    for _ in range(operation_count):
        operation, a, b = values[index:index + 3]
        index += 3
        if operation == 0:
            if (not 0 <= a < MAX_VERTEX_ID_EXCLUSIVE or b != 0 or vertex_index(a) >= 0
                    or len(vertices) >= MAX_VERTICES):
                return -1, b""
            vertices.append(a)
            results.append(1)
        elif operation == 1:
            removed = vertex_index(a)
            if removed < 0 or b != 0:
                return -1, b""
            del vertices[removed]
            for row in matrix:
                del row[removed]
            del matrix[removed]
            for row in matrix:
                row.append(0)
            matrix.append([0] * MAX_VERTICES)
            results.append(1)
        elif operation in (2, 3, 5):
            source_index = vertex_index(a)
            destination_index = vertex_index(b)
            if source_index < 0 or destination_index < 0:
                return -1, b""
            present = matrix[source_index][destination_index] != 0
            if operation == 2:
                if present:
                    return -1, b""
                matrix[source_index][destination_index] = 1
                if not directed:
                    matrix[destination_index][source_index] = 1
                results.append(1)
            elif operation == 3:
                if not present:
                    return -1, b""
                matrix[source_index][destination_index] = 0
                if not directed:
                    matrix[destination_index][source_index] = 0
                results.append(1)
            else:
                results.append(int(present))
        elif operation == 4:
            if not 0 <= a < MAX_VERTEX_ID_EXCLUSIVE or b != 0:
                return -1, b""
            results.append(int(vertex_index(a) >= 0))
        elif operation == 6:
            if a != 0 or b != 0:
                return -1, b""
            vertices.clear()
            matrix = [[0] * MAX_VERTICES for _ in range(MAX_VERTICES)]
            results.append(1)
        else:
            return -1, b""

    output = [operation_count, *results, len(vertices), *vertices]
    for row in range(len(vertices)):
        output.extend(matrix[row][:len(vertices)])
    data = struct.pack("<" + "q" * len(output), *output)
    return len(data), data
