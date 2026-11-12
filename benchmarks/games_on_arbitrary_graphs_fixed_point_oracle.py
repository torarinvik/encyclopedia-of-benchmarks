"""Independent synchronous attractor fixed-point oracle for directed graph games."""

MAX_VERTICES = 16
MAX_EDGES = 32
MAX_INPUT_LENGTH = 66
MAX_OUTPUT_BYTES = 17
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _read_graph(values, input_is_null=False, input_length=None):
    if (not isinstance(values, (list, tuple)) or len(values) > MAX_INPUT_LENGTH
            or type(input_is_null) is not bool or (input_is_null and len(values) != 0)
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))):
        return None
    for value in values:
        if type(value) is not int or value < I64_MIN or value > I64_MAX:
            return None
    if input_is_null or len(values) < 2:
        return None
    n, m = int(values[0]), int(values[1])
    if n < 0 or n > MAX_VERTICES or m < 0 or m > MAX_EDGES:
        return None
    if len(values) != 2 + 2*m:
        return None
    successors = [set() for _ in range(n)]
    for edge in range(m):
        source, target = values[2+2*edge:4+2*edge]
        if source < 0 or target < 0 or source >= n or target >= n:
            return None
        successors[source].add(target)
    return successors


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (type(output_is_null) is not bool
            or (output_capacity is not None
                and (type(output_capacity) is not int or output_capacity < 0))):
        return -1, b""
    successors = _read_graph(values, input_is_null, input_length)
    if successors is None:
        return -1, b""
    n = len(successors)
    status = [0] * n  # 0 unresolved/draw, 1 win, 2 loss
    for vertex in range(n):
        if not successors[vertex]:
            status[vertex] = 2
    while True:
        updated = status.copy()
        for vertex in range(n):
            if status[vertex] != 0 or not successors[vertex]:
                continue
            if any(status[target] == 2 for target in successors[vertex]):
                updated[vertex] = 1
            elif all(status[target] == 1 for target in successors[vertex]):
                updated[vertex] = 2
        if updated == status:
            break
        status = updated
    encoded = bytes([n, *status])
    if output_is_null or (output_capacity is not None and output_capacity < len(encoded)):
        return -2, b""
    return len(encoded), encoded
