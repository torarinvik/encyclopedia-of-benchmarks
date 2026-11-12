"""Bitset oracle and independent tree-decomposition certificate checker."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 32
MAX_M = 64
MAX_INPUT_LENGTH = 2 + 2 * MAX_M + 1
MAX_OUTPUT_BYTES = 8 * (6 * MAX_N + 7)


def _parse(values: Sequence[int] | None, input_length: int | None):
    if (values is None or not isinstance(values, (list, tuple))
            or len(values) < 2 or len(values) > MAX_INPUT_LENGTH
            or input_length is not None and
                (type(input_length) is not int or input_length != len(values))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, edge_count = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= edge_count <= min(MAX_M, n * (n - 1) // 2):
        return None
    if len(values) != 2 + 2 * edge_count:
        return None
    masks = [0] * n
    edges: list[tuple[int, int]] = []
    for index in range(edge_count):
        left, right = values[2 + 2 * index:4 + 2 * index]
        if not 0 <= left < right < n or masks[left] >> right & 1:
            return None
        masks[left] |= 1 << right
        masks[right] |= 1 << left
        edges.append((left, right))
    return n, masks, edges


def _encode(words: list[int]) -> bytes:
    output = bytearray()
    for word in words:
        output.extend(word.to_bytes(8, "little", signed=True))
    return bytes(output)


def evaluate(values: Sequence[int] | None, input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_length)
    if parsed is None:
        return -1, b""
    n, adjacency, _ = parsed
    alive = (1 << n) - 1
    elimination: list[int] = []
    bags: list[list[int]] = []
    later: list[list[int]] = []

    for _ in range(n):
        selected = -1
        neighbors: list[int] = []
        for vertex in range(n):
            if alive >> vertex & 1:
                active = adjacency[vertex] & alive
                if active.bit_count() <= 2:
                    selected = vertex
                    neighbors = [other for other in range(n) if active >> other & 1]
                    break
        if selected < 0:
            return -1, b""
        elimination.append(selected)
        later.append(neighbors)
        bags.append(sorted([selected, *neighbors]))
        if len(neighbors) == 2:
            a, b = neighbors
            adjacency[a] |= 1 << b
            adjacency[b] |= 1 << a
        alive &= ~(1 << selected)

    rank = [0] * n
    for index, vertex in enumerate(elimination):
        rank[vertex] = index
    root = n
    parents = [min(neighbors, key=rank.__getitem__) if neighbors else root
               for neighbors in later]
    words = [n + 1, 2, n]
    for bag in (*bags, []):
        words.extend((len(bag), *bag, *([-1] * (3 - len(bag)))))
    for child, parent in enumerate(parents):
        words.extend((child, parent))
    return len(words) * 8, _encode(words)


def validate_output(values: Sequence[int] | None, output: bytes) -> bool:
    if not isinstance(values, (list, tuple)) or not isinstance(output, (bytes, bytearray)):
        return False
    parsed = _parse(values, len(values))
    if parsed is None:
        return False
    n, _, graph_edges = parsed
    expected_bytes = 8 * (6 * n + 7)
    if len(output) != expected_bytes:
        return False
    words = [int.from_bytes(output[offset:offset + 8], "little", signed=True)
             for offset in range(0, len(output), 8)]
    k, width, declared_n = words[:3]
    if k != n + 1 or declared_n != n or not 0 <= width <= 2:
        return False

    bags: list[set[int]] = []
    cursor = 3
    for bag_index in range(k):
        size = words[cursor]
        entries = words[cursor + 1:cursor + 4]
        cursor += 4
        if (not 0 <= size <= width + 1
                or any(vertex < 0 or vertex >= n for vertex in entries[:size])
                or len(set(entries[:size])) != size
                or any(vertex != -1 for vertex in entries[size:])):
            return False
        if bag_index < n and size == 0:
            return False
        if bag_index == n and size != 0:
            return False
        bags.append(set(entries[:size]))

    tree: list[list[int]] = [[] for _ in range(k)]
    seen_edges: set[tuple[int, int]] = set()
    for _ in range(k - 1):
        left, right = words[cursor:cursor + 2]
        cursor += 2
        if not 0 <= left < k or not 0 <= right < k or left == right:
            return False
        edge = (min(left, right), max(left, right))
        if edge in seen_edges:
            return False
        seen_edges.add(edge)
        tree[left].append(right)
        tree[right].append(left)
    if cursor != len(words):
        return False

    reached = {0}
    stack = [0]
    while stack:
        node = stack.pop()
        for neighbor in tree[node]:
            if neighbor not in reached:
                reached.add(neighbor)
                stack.append(neighbor)
    if len(reached) != k:
        return False

    for left, right in graph_edges:
        if not any(left in bag and right in bag for bag in bags):
            return False
    for vertex in range(n):
        occurrences = {index for index, bag in enumerate(bags) if vertex in bag}
        if not occurrences:
            return False
        reached_occurrences = {next(iter(occurrences))}
        stack = list(reached_occurrences)
        while stack:
            node = stack.pop()
            for neighbor in tree[node]:
                if neighbor in occurrences and neighbor not in reached_occurrences:
                    reached_occurrences.add(neighbor)
                    stack.append(neighbor)
        if reached_occurrences != occurrences:
            return False
    return True


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or output_capacity is not None and
                (type(output_capacity) is not int or output_capacity < 0)
            or input_length is not None and
                (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH)):
        return -1, b""
    if input_is_null:
        return -1, b""
    result, output = evaluate(values, input_length)
    if result < 0:
        return result, output
    if output_is_null or output_capacity is not None and output_capacity < result:
        return -2, b""
    return result, output
