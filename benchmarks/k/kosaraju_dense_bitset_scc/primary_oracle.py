"""Packed-row, iterative Kosaraju reference for the dense SCC profile."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_VERTICES = 256
MAX_WORDS = 4
MAX_VALID_INPUT_LENGTH = 1 + MAX_VERTICES * MAX_WORDS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 2 + 2 * MAX_VERTICES
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
    word_count = (n + 63) // 64
    if len(values) != 1 + n * word_count:
        return None
    rows = []
    last_bits = n & 63
    last_mask = (1 << last_bits) - 1 if last_bits else U64_MASK
    for vertex in range(n):
        row = [value & U64_MASK for value in
               values[1 + vertex * word_count:1 + (vertex + 1) * word_count]]
        if row[-1] & ~last_mask:
            return None
        rows.append(row)
    return n, word_count, rows


def _canonical_output(raw_component, component_count):
    minima = [len(raw_component)] * component_count
    for vertex, component in enumerate(raw_component):
        if vertex < minima[component]:
            minima[component] = vertex
    raw_ids = sorted(range(component_count), key=minima.__getitem__)
    canonical = [0] * component_count
    for label, raw_id in enumerate(raw_ids):
        canonical[raw_id] = label
    labels = [canonical[component] for component in raw_component]
    encoded = bytearray()
    encoded.extend(component_count.to_bytes(2, "little"))
    for label in labels:
        encoded.extend(label.to_bytes(2, "little"))
    return bytes(encoded)


def expected_output(values, output_capacity=None, input_is_null=False,
                    output_is_null=False, input_length=None):
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1, b""
    if type(output_is_null) is not bool:
        return -1, b""
    n, word_count, adjacency = decoded

    transpose = [[0] * word_count for _ in range(n)]
    for source, row in enumerate(adjacency):
        for word, packed in enumerate(row):
            bits = packed
            while bits:
                lowest = bits & -bits
                target = word * 64 + lowest.bit_length() - 1
                transpose[target][source // 64] |= 1 << (source & 63)
                bits ^= lowest

    unvisited = [U64_MASK] * word_count
    if n & 63:
        unvisited[-1] = (1 << (n & 63)) - 1
    order = []
    for root in range(n):
        root_word, root_bit = divmod(root, 64)
        if not (unvisited[root_word] >> root_bit) & 1:
            continue
        unvisited[root_word] &= ~(1 << root_bit)
        stack = [[root, 0]]
        while stack:
            vertex, word = stack[-1]
            while word < word_count:
                candidates = adjacency[vertex][word] & unvisited[word]
                if candidates:
                    lowest = candidates & -candidates
                    neighbor = word * 64 + lowest.bit_length() - 1
                    unvisited[word] &= ~lowest
                    stack.append([neighbor, 0])
                    break
                word += 1
                stack[-1][1] = word
            else:
                order.append(vertex)
                stack.pop()

    if n & 63:
        unvisited[-1] = (1 << (n & 63)) - 1
    component = [-1] * n
    component_count = 0
    for root in reversed(order):
        root_word, root_bit = divmod(root, 64)
        if not (unvisited[root_word] >> root_bit) & 1:
            continue
        unvisited[root_word] &= ~(1 << root_bit)
        component[root] = component_count
        stack = [root]
        while stack:
            vertex = stack.pop()
            for word in range(word_count):
                candidates = transpose[vertex][word] & unvisited[word]
                while candidates:
                    lowest = candidates & -candidates
                    neighbor = word * 64 + lowest.bit_length() - 1
                    unvisited[word] &= ~lowest
                    component[neighbor] = component_count
                    stack.append(neighbor)
                    candidates ^= lowest
        component_count += 1

    output = _canonical_output(component, component_count)
    if (output_is_null or (output_capacity is not None
                           and (type(output_capacity) is not int
                                or output_capacity < len(output)))):
        return -2, b""
    return len(output), output


def expected_result(values, output_capacity=None, input_is_null=False,
                    output_is_null=False, input_length=None):
    return expected_output(values, output_capacity, input_is_null,
                           output_is_null, input_length)[0]
