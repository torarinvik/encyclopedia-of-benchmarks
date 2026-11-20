"""Simple-cycle enumeration reference for minimum weighted undirected cycle."""

import struct

MAX_N = 9
MAX_EDGES = MAX_N * (MAX_N - 1) // 2
MAX_VALID_INPUT_LENGTH = 2 + 3 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8
MAX_WORKSPACE_BYTES = 4096


def _accepted(values, input_is_null, input_length):
    if type(input_is_null) is not bool or input_is_null:
        return False
    if not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return False
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return False
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return False
    n, m = values[:2]
    if not 3 <= n <= MAX_N or not 0 <= m <= n * (n - 1) // 2:
        return False
    if len(values) != 2 + 3 * m:
        return False
    seen = set()
    for index in range(m):
        u, v, weight = values[2 + 3 * index:5 + 3 * index]
        if not 0 <= u < n or not 0 <= v < n or u == v or not 1 <= weight <= 1000:
            return False
        edge = (min(u, v), max(u, v))
        if edge in seen:
            return False
        seen.add(edge)
    return True


def evaluate(values, input_is_null=False, input_length=None):
    if not _accepted(values, input_is_null, input_length):
        return -1, b""
    n, m = values[:2]
    weight = [[None] * n for _ in range(n)]
    for index in range(m):
        u, v, cost = values[2 + 3 * index:5 + 3 * index]
        weight[u][v] = weight[v][u] = cost

    best = None
    # The least-numbered vertex is the unique start for each cycle. Requiring
    # first < last retains one orientation and removes its reversal.
    for start in range(n):
        path = [start]
        used = {start}

        def visit(last, partial):
            nonlocal best
            for nxt in range(start + 1, n):
                if nxt == start or nxt in used or weight[last][nxt] is None:
                    continue
                new_cost = partial + weight[last][nxt]
                if new_cost >= (best if best is not None else 1 << 62):
                    continue
                if len(path) >= 2 and weight[nxt][start] is not None:
                    if path[1] < nxt:
                        cycle_cost = new_cost + weight[nxt][start]
                        if best is None or cycle_cost < best:
                            best = cycle_cost
                used.add(nxt)
                path.append(nxt)
                visit(nxt, new_cost)
                path.pop()
                used.remove(nxt)

        visit(start, 0)

    value = -1 if best is None else best
    payload = struct.pack("<q", value)
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
