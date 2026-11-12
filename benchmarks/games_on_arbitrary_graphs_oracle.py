"""Primary reverse-edge retrograde oracle for games on directed graphs."""

MAX_VERTICES = 16
MAX_EDGES = 32
MAX_INPUT_LENGTH = 66
MAX_OUTPUT_BYTES = 17
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _parse(values, input_is_null, input_length):
    if (not isinstance(values, (list, tuple)) or len(values) > MAX_INPUT_LENGTH
            or type(input_is_null) is not bool or (input_is_null and values)
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_is_null or len(values) < 2:
        return None
    n, m = values[:2]
    if not (0 <= n <= MAX_VERTICES and 0 <= m <= MAX_EDGES):
        return None
    if len(values) != 2 + 2*m:
        return None
    outgoing = [set() for _ in range(n)]
    incoming = [[] for _ in range(n)]
    for pos in range(2, len(values), 2):
        source, target = values[pos], values[pos+1]
        if not (0 <= source < n and 0 <= target < n):
            return None
        if target not in outgoing[source]:
            outgoing[source].add(target)
            incoming[target].append(source)
    return outgoing, incoming


def _encode(states):
    return bytes([len(states), *states])


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (type(output_is_null) is not bool
            or (output_capacity is not None
                and (type(output_capacity) is not int or output_capacity < 0))):
        return -1, b""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    outgoing, incoming = parsed
    n = len(outgoing)
    remaining = [len(neighbors) for neighbors in outgoing]
    status = [0] * n  # 0 unresolved/draw, 1 win, 2 loss
    queue = []
    for vertex in range(n):
        if remaining[vertex] == 0:
            status[vertex] = 2
            queue.append(vertex)
    head = 0
    while head < len(queue):
        resolved = queue[head]
        head += 1
        for predecessor in incoming[resolved]:
            if status[predecessor] != 0:
                continue
            if status[resolved] == 2:
                status[predecessor] = 1
                queue.append(predecessor)
            else:
                remaining[predecessor] -= 1
                if remaining[predecessor] == 0:
                    status[predecessor] = 2
                    queue.append(predecessor)
    encoded = _encode(status)
    if output_is_null or (output_capacity is not None and output_capacity < len(encoded)):
        return -2, b""
    return len(encoded), encoded
