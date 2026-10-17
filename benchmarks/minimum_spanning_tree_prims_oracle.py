"""Oracle for the bounded pinned Python indexed-heap Prim implementation."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MIN_VERTEX_COUNT = 1
MAX_VERTEX_COUNT = 16
MAX_EDGE_COUNT = 64
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
SOURCE_HEAP_SENTINEL = (1 << 63) - 1
MAX_INPUT_LENGTH = 2 + 3 * MAX_EDGE_COUNT
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_WORDS = 1 + 2 * (MAX_VERTEX_COUNT - 1)
MAX_OUTPUT_BYTES = 4 * MAX_OUTPUT_WORDS
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _top_to_bottom(
    heap: list[int],
    start: int,
    positions: list[int],
    node_position: list[int],
) -> None:
    """Match source heapify: choose the right child on ties, swap only on <."""
    size = len(heap)
    if start > size // 2 - 1:
        return
    left_child = 2 * start + 1
    right_child = 2 * start + 2
    if right_child >= size:
        smallest_child = left_child
    elif heap[left_child] < heap[right_child]:
        smallest_child = left_child
    else:
        smallest_child = right_child

    if heap[smallest_child] < heap[start]:
        heap[start], heap[smallest_child] = heap[smallest_child], heap[start]
        positions[start], positions[smallest_child] = positions[smallest_child], positions[start]
        node_position[positions[start]] = start
        node_position[positions[smallest_child]] = smallest_child
        _top_to_bottom(heap, smallest_child, positions, node_position)


def _heapify(heap: list[int], positions: list[int], node_position: list[int]) -> None:
    for start in range(len(heap) // 2 - 1, -1, -1):
        _top_to_bottom(heap, start, positions, node_position)


def _delete_minimum(
    heap: list[int], positions: list[int], node_position: list[int]
) -> int:
    minimum_vertex = positions[0]
    heap[0] = SOURCE_HEAP_SENTINEL
    _top_to_bottom(heap, 0, positions, node_position)
    return minimum_vertex


def _decrease_key(
    value: int,
    index: int,
    heap: list[int],
    positions: list[int],
    node_position: list[int],
) -> None:
    vertex = positions[index]
    while index != 0:
        parent = (index - 2) // 2 if index % 2 == 0 else (index - 1) // 2
        if value < heap[parent]:
            heap[index] = heap[parent]
            positions[index] = positions[parent]
            node_position[positions[parent]] = index
        else:
            heap[index] = value
            positions[index] = vertex
            node_position[vertex] = index
            break
        index = parent
    else:
        heap[0] = value
        positions[0] = vertex
        node_position[vertex] = 0


def _is_connected(adjacency: list[list[tuple[int, int]]]) -> bool:
    visited = {0}
    pending = [0]
    while pending:
        vertex = pending.pop()
        for neighbor, _weight in adjacency[vertex]:
            if neighbor not in visited:
                visited.add(neighbor)
                pending.append(neighbor)
    return len(visited) == len(adjacency)


def _prim_edges(adjacency: list[list[tuple[int, int]]]) -> list[tuple[int, int]]:
    """Run the source's indexed heap and return its parent-child extraction trace."""
    vertex_count = len(adjacency)
    visited = [False] * vertex_count
    parent = [-1] * vertex_count
    heap = [SOURCE_HEAP_SENTINEL] * vertex_count
    positions = list(range(vertex_count))
    node_position = list(range(vertex_count))

    visited[0] = True
    for neighbor, weight in adjacency[0]:
        parent[neighbor] = 0
        heap[neighbor] = weight
    _heapify(heap, positions, node_position)

    tree_edges: list[tuple[int, int]] = []
    for _ in range(1, vertex_count):
        vertex = _delete_minimum(heap, positions, node_position)
        if not visited[vertex]:
            tree_edges.append((parent[vertex], vertex))
            visited[vertex] = True
            for neighbor, weight in adjacency[vertex]:
                heap_index = node_position[neighbor]
                if not visited[neighbor] and weight < heap[heap_index]:
                    heap[heap_index] = weight
                    _decrease_key(weight, heap_index, heap, positions, node_position)
                    parent[neighbor] = vertex
    return tree_edges


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return `[n-1, (parent, child)...]` as little-endian signed-i32 bytes."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length < 0
    ):
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    if not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT, b""
    if any(type(value) is not int or not I32_MIN <= value <= I32_MAX for value in values):
        return INVALID_RESULT, b""

    vertex_count, edge_count = values[:2]
    if not MIN_VERTEX_COUNT <= vertex_count <= MAX_VERTEX_COUNT:
        return INVALID_RESULT, b""
    if not 0 <= edge_count <= MAX_EDGE_COUNT:
        return INVALID_RESULT, b""
    if len(values) != 2 + 3 * edge_count:
        return INVALID_RESULT, b""

    adjacency: list[list[tuple[int, int]]] = [[] for _ in range(vertex_count)]
    seen_edges: set[tuple[int, int]] = set()
    for edge_index in range(edge_count):
        offset = 2 + 3 * edge_index
        left, right, weight = values[offset : offset + 3]
        if not 0 <= left < right < vertex_count:
            return INVALID_RESULT, b""
        edge = (left, right)
        if edge in seen_edges:
            return INVALID_RESULT, b""
        seen_edges.add(edge)
        adjacency[left].append((right, weight))
        adjacency[right].append((left, weight))

    if vertex_count > 1 and not _is_connected(adjacency):
        return INVALID_RESULT, b""

    tree_edges = _prim_edges(adjacency)
    output_words = [len(tree_edges)]
    for parent, child in tree_edges:
        output_words.extend((parent, child))
    encoded = struct.pack("<" + "i" * len(output_words), *output_words)
    if len(encoded) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null or (
        output_capacity is not None and output_capacity < len(encoded)
    ):
        return OUTPUT_ERROR, b""
    return len(encoded), encoded
