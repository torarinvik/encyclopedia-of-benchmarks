"""Runtime oracle for a bounded serialized KD tree nearest-neighbor search."""
import struct

MAX_INPUT_LENGTH = 80
MAX_OUTPUT_BYTES = 48


def expected_output(values):
    if (not isinstance(values, (list, tuple)) or len(values) < 1
            or any(type(x) is not int or not -(2**63) <= x < 2**63 for x in values)):
        return -1, b""
    if len(values) < 5:
        return -1, b""
    dim, count = values[:2]
    if dim not in (2, 3) or not 1 <= count <= 15 or len(values) != 2 + dim + count * (dim + 2):
        return -1, b""
    query = values[2:2 + dim]
    if any(not -1000 <= x <= 1000 for x in query):
        return -1, b""
    offset = 2 + dim
    nodes = []
    for i in range(count):
        record = values[offset + i * (dim + 2):offset + (i + 1) * (dim + 2)]
        point, left, right = record[:dim], record[dim:]
        if any(not -1000 <= x <= 1000 for x in point):
            return -1, b""
        if any(child < -1 or child >= count for child in (left, right)) or (left >= 0 and left == right):
            return -1, b""
        nodes.append((point, left, right))
    seen = set()

    def validate(index):
        if index in seen:
            return False
        seen.add(index)
        _, left, right = nodes[index]
        return (left < 0 or validate(left)) and (right < 0 or validate(right))

    if not validate(0) or len(seen) != count:
        return -1, b""
    best_point = None
    best_distance = None
    visited = 0

    def search(index, depth):
        nonlocal best_point, best_distance, visited
        if index < 0:
            return
        visited += 1
        point, left, right = nodes[index]
        distance = sum((q - p) ** 2 for q, p in zip(query, point))
        if best_distance is None or distance < best_distance:
            best_point, best_distance = point, distance
        axis = depth % dim
        if query[axis] <= point[axis]:
            near, far = left, right
        else:
            near, far = right, left
        search(near, depth + 1)
        split = query[axis] - point[axis]
        if split * split < best_distance:
            search(far, depth + 1)

    search(0, 0)
    padded = list(best_point) + [0] * (3 - dim)
    result = [dim, *padded, best_distance, visited]
    payload = struct.pack("<6q", *result)
    return len(payload), payload
