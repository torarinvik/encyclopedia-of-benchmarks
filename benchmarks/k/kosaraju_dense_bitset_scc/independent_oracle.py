"""Adjacency-list Tarjan reference, independent of the packed Kosaraju port."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_VERTICES = 256
MAX_PARSEABLE_INPUT_LENGTH = 1026
U64_MASK = (1 << 64) - 1


def _decode(values, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) < 1 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (type(input_length) is not int
                                     or input_length != len(values)):
        return None
    n = values[0]
    if not 1 <= n <= MAX_VERTICES:
        return None
    words = (n + 63) // 64
    if len(values) != 1 + n * words:
        return None
    last_bits = n & 63
    last_mask = (1 << last_bits) - 1 if last_bits else U64_MASK
    adjacency = [[] for _ in range(n)]
    for source in range(n):
        row = values[1 + source * words:1 + (source + 1) * words]
        for word, signed_value in enumerate(row):
            bits = signed_value & U64_MASK
            if word == words - 1 and bits & ~last_mask:
                return None
            while bits:
                low_bit = bits & -bits
                target = word * 64 + low_bit.bit_length() - 1
                adjacency[source].append(target)
                bits ^= low_bit
    return n, adjacency


def _tarjan(adjacency):
    n = len(adjacency)
    discovery = [-1] * n
    low = [0] * n
    on_stack = [False] * n
    stack = []
    raw_component = [-1] * n
    next_time = 0
    component_count = 0

    def visit(vertex):
        nonlocal next_time, component_count
        discovery[vertex] = low[vertex] = next_time
        next_time += 1
        stack.append(vertex)
        on_stack[vertex] = True
        for neighbor in adjacency[vertex]:
            if discovery[neighbor] == -1:
                visit(neighbor)
                low[vertex] = min(low[vertex], low[neighbor])
            elif on_stack[neighbor]:
                low[vertex] = min(low[vertex], discovery[neighbor])
        if low[vertex] == discovery[vertex]:
            while True:
                member = stack.pop()
                on_stack[member] = False
                raw_component[member] = component_count
                if member == vertex:
                    break
            component_count += 1

    for vertex in range(n):
        if discovery[vertex] == -1:
            visit(vertex)
    minima = [n] * component_count
    for vertex, raw_id in enumerate(raw_component):
        minima[raw_id] = min(minima[raw_id], vertex)
    raw_order = sorted(range(component_count), key=minima.__getitem__)
    remap = [0] * component_count
    for label, raw_id in enumerate(raw_order):
        remap[raw_id] = label
    labels = [remap[raw_id] for raw_id in raw_component]
    output = bytearray(component_count.to_bytes(2, "little"))
    for label in labels:
        output.extend(label.to_bytes(2, "little"))
    return bytes(output)


def expected_output(values, output_capacity=None, input_is_null=False,
                    output_is_null=False, input_length=None):
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1, b""
    if type(output_is_null) is not bool:
        return -1, b""
    _, adjacency = decoded
    output = _tarjan(adjacency)
    if (output_is_null or (output_capacity is not None
                           and (type(output_capacity) is not int
                                or output_capacity < len(output)))):
        return -2, b""
    return len(output), output


def expected_result(values, output_capacity=None, input_is_null=False,
                    output_is_null=False, input_length=None):
    return expected_output(values, output_capacity, input_is_null,
                           output_is_null, input_length)[0]
