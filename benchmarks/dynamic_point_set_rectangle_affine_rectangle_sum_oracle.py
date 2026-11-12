"""Direct point-list oracle for dynamic 2D affine rectangle operations."""

from __future__ import annotations

import struct

MAX_N = 32
MAX_Q = 32
MAX_POINTS = MAX_N + MAX_Q
MAX_COORD = 1_000_000_000
MOD = 998_244_353
MAX_VALID_INPUT_LENGTH = 2 + 3 * MAX_N + 7 * MAX_Q
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * MAX_Q
MAX_WORKSPACE_BYTES = MAX_OUTPUT_BYTES


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Validate the full operation stream, then simulate it by scanning point lists."""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    effective_length = len(values) if input_length is None else input_length
    if (type(effective_length) is not int or effective_length < 2
            or effective_length > MAX_PARSEABLE_INPUT_LENGTH
            or effective_length != len(values)
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""

    n, q = values[:2]
    if not 1 <= n <= MAX_N or not 1 <= q <= MAX_Q or 2 + 3 * n > len(values):
        return -1, b""
    points = []
    for index in range(n):
        x, y, weight = values[2 + 3 * index: 5 + 3 * index]
        if not (0 <= x <= MAX_COORD and 0 <= y <= MAX_COORD and 0 <= weight < MOD):
            return -1, b""
        points.append([x, y, weight, True])

    cursor = 2 + 3 * n
    operations = []
    query_count = 0
    active_point_count = n
    for _ in range(q):
        if cursor >= len(values):
            return -1, b""
        kind = values[cursor]
        cursor += 1
        if kind == 0:
            if cursor + 3 > len(values):
                return -1, b""
            x, y, weight = values[cursor:cursor + 3]
            cursor += 3
            if not (0 <= x <= MAX_COORD and 0 <= y <= MAX_COORD and 0 <= weight < MOD):
                return -1, b""
            point_id = active_point_count
            points.append([x, y, 0, False])
            operations.append((0, point_id, weight))
            active_point_count += 1
        elif kind == 1:
            if cursor + 2 > len(values):
                return -1, b""
            point_id, weight = values[cursor:cursor + 2]
            cursor += 2
            if not 0 <= point_id < active_point_count:
                return -1, b""
            if not 0 <= weight < MOD:
                return -1, b""
            operations.append((1, point_id, weight))
        elif kind == 2:
            if cursor + 4 > len(values):
                return -1, b""
            left, down, right, up = values[cursor:cursor + 4]
            cursor += 4
            if not (0 <= left < right <= MAX_COORD and 0 <= down < up <= MAX_COORD):
                return -1, b""
            operations.append((2, left, down, right, up))
            query_count += 1
        elif kind == 3:
            if cursor + 6 > len(values):
                return -1, b""
            left, down, right, up, a, b = values[cursor:cursor + 6]
            cursor += 6
            if not (0 <= left < right <= MAX_COORD and 0 <= down < up <= MAX_COORD
                    and 0 <= a < MOD and 0 <= b < MOD):
                return -1, b""
            operations.append((3, left, down, right, up, a, b))
        else:
            return -1, b""
    if cursor != len(values):
        return -1, b""

    required = 8 * query_count
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if required > 0 and (output_is_null or effective_capacity < required):
        return -2, b""

    answers = []
    for operation in operations:
        if operation[0] == 0:
            _, point_id, weight = operation
            points[point_id][2] = weight
            points[point_id][3] = True
        elif operation[0] == 1:
            _, point_id, weight = operation
            points[point_id][2] = weight
        elif operation[0] == 2:
            _, left, down, right, up = operation
            answers.append(sum(point[2] for point in points if point[3]
                               and left <= point[0] < right and down <= point[1] < up) % MOD)
        else:
            _, left, down, right, up, a, b = operation
            for point in points:
                if (point[3] and left <= point[0] < right
                        and down <= point[1] < up):
                    point[2] = (a * point[2] + b) % MOD
    payload = b"".join(struct.pack("<q", answer) for answer in answers)
    return len(payload), payload
