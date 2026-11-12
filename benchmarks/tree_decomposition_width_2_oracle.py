"""Primary bounded degree-two elimination oracle and certificate serializer."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 32
MAX_M = 64
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_M
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_WORDS = 6 * MAX_N + 7
MAX_OUTPUT_BYTES = 8 * MAX_OUTPUT_WORDS
MAX_WORKSPACE_BYTES = MAX_OUTPUT_BYTES


def _parse(values: Sequence[int] | None, input_length: int | None):
    if (values is None or not isinstance(values, (tuple, list))
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
    adjacent = [set() for _ in range(n)]
    seen: set[tuple[int, int]] = set()
    for index in range(edge_count):
        left, right = values[2 + 2 * index:4 + 2 * index]
        if not 0 <= left < right < n or (left, right) in seen:
            return None
        seen.add((left, right))
        adjacent[left].add(right)
        adjacent[right].add(left)
    return n, adjacent


def _pack(words: list[int]) -> bytes:
    return b"".join(value.to_bytes(8, "little", signed=True) for value in words)


def evaluate(values: Sequence[int] | None, input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_length)
    if parsed is None:
        return -1, b""
    n, adjacent = parsed
    alive = [True] * n
    elimination: list[int] = []
    bag_vertices: list[list[int]] = []
    later_neighbors: list[list[int]] = []

    for _ in range(n):
        chosen = -1
        neighbors: list[int] = []
        for vertex in range(n):
            if not alive[vertex]:
                continue
            active_neighbors = [other for other in sorted(adjacent[vertex]) if alive[other]]
            if len(active_neighbors) <= 2:
                chosen = vertex
                neighbors = active_neighbors
                break
        if chosen < 0:
            return -1, b""

        elimination.append(chosen)
        later_neighbors.append(neighbors)
        bag_vertices.append(sorted((chosen, *neighbors)))
        if len(neighbors) == 2:
            left, right = neighbors
            adjacent[left].add(right)
            adjacent[right].add(left)
        alive[chosen] = False

    position = [0] * n
    for step, vertex in enumerate(elimination):
        position[vertex] = step
    root = n
    parent: list[int] = []
    for neighbors in later_neighbors:
        parent.append(min(neighbors, key=position.__getitem__) if neighbors else root)

    # The extra empty root joins the elimination-tree roots of disconnected
    # components. Each real bag has one parent and each parent is later.
    words = [n + 1, 2, n]
    for bag in (*bag_vertices, []):
        words.append(len(bag))
        words.extend(bag)
        words.extend([-1] * (3 - len(bag)))
    for bag_index, parent_index in enumerate(parent):
        words.extend((bag_index, parent_index))
    return len(words) * 8, _pack(words)


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
    result, payload = evaluate(values, input_length)
    if result < 0:
        return result, payload
    if output_is_null or output_capacity is not None and output_capacity < result:
        return -2, b""
    return result, payload
