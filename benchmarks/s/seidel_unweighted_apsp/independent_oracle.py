"""All-pairs breadth-first search for the bounded Seidel contract."""

from collections import deque
import struct

MAX_INPUT_LENGTH = 66
MAX_OUTPUT_BYTES = 512


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or type(output_is_null) is not bool
            or input_is_null or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    n = values[0]
    if not 1 <= n <= 8 or len(values) != 1 + n * n:
        return -1, b""
    matrix = [values[1 + i * n:1 + (i + 1) * n] for i in range(n)]
    if (any(value not in (0, 1) for row in matrix for value in row)
            or any(matrix[i][i] != 0 for i in range(n))
            or any(matrix[i][j] != matrix[j][i] for i in range(n) for j in range(i))):
        return -1, b""
    distances = []
    for start in range(n):
        row = [-1] * n
        row[start] = 0
        queue = deque([start])
        while queue:
            vertex = queue.popleft()
            for target, edge in enumerate(matrix[vertex]):
                if edge and row[target] < 0:
                    row[target] = row[vertex] + 1
                    queue.append(target)
        if -1 in row:
            return -1, b""
        distances.extend(row)
    required = 8 * n * n
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < required)):
        return -2, b""
    return required, b"".join(struct.pack("<q", value) for value in distances)
