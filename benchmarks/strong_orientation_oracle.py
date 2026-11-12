"""Independent reference and certificate checker for strong orientation."""
from __future__ import annotations

import struct
from typing import Sequence

MAX_VERTICES = 64
MAX_EDGES = 128
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (MAX_EDGES + 1)
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY_RESULT = -2


def _components(vertex_count: int, edges: Sequence[tuple[int, int]],
                omitted_edge: int = -1) -> int:
    adjacency: list[list[int]] = [[] for _ in range(vertex_count)]
    for edge_id, (left, right) in enumerate(edges):
        if edge_id == omitted_edge:
            continue
        adjacency[left].append(right)
        adjacency[right].append(left)
    seen = [False] * vertex_count
    count = 0
    for start in range(vertex_count):
        if seen[start]:
            continue
        count += 1
        seen[start] = True
        stack = [start]
        while stack:
            vertex = stack.pop()
            for neighbor in adjacency[vertex]:
                if not seen[neighbor]:
                    seen[neighbor] = True
                    stack.append(neighbor)
    return count


def _directions(vertex_count: int, edges: Sequence[tuple[int, int]]) -> list[int]:
    """Iterative DFS with explicit frames, preserving recursive input order."""
    adjacency: list[list[tuple[int, int]]] = [[] for _ in range(vertex_count)]
    for edge_id, (left, right) in enumerate(edges):
        adjacency[left].append((right, edge_id))
        adjacency[right].append((left, edge_id))
    discovery = [-1] * vertex_count
    used = [False] * len(edges)
    directions = [0] * len(edges)
    timer = 0
    for root in range(vertex_count):
        if discovery[root] != -1:
            continue
        discovery[root] = timer
        timer += 1
        frames: list[tuple[int, int]] = [(root, 0)]
        while frames:
            vertex, next_index = frames[-1]
            if next_index == len(adjacency[vertex]):
                frames.pop()
                continue
            frames[-1] = (vertex, next_index + 1)
            neighbor, edge_id = adjacency[vertex][next_index]
            if used[edge_id]:
                continue
            used[edge_id] = True
            left, _ = edges[edge_id]
            directions[edge_id] = 1 if vertex == left else -1
            if discovery[neighbor] == -1:
                discovery[neighbor] = timer
                timer += 1
                frames.append((neighbor, 0))
    return directions


def _directed_component_count(vertex_count: int, edges: Sequence[tuple[int, int]],
                              directions: Sequence[int]) -> int:
    forward: list[list[int]] = [[] for _ in range(vertex_count)]
    reverse: list[list[int]] = [[] for _ in range(vertex_count)]
    for (left, right), direction in zip(edges, directions):
        source, target = (left, right) if direction == 1 else (right, left)
        forward[source].append(target)
        reverse[target].append(source)
    seen = [False] * vertex_count
    order: list[int] = []
    for start in range(vertex_count):
        if seen[start]:
            continue
        seen[start] = True
        stack: list[tuple[int, int]] = [(start, 0)]
        while stack:
            vertex, index = stack[-1]
            if index < len(forward[vertex]):
                stack[-1] = (vertex, index + 1)
                neighbor = forward[vertex][index]
                if not seen[neighbor]:
                    seen[neighbor] = True
                    stack.append((neighbor, 0))
            else:
                order.append(vertex)
                stack.pop()
    assigned = [False] * vertex_count
    components = 0
    for start in reversed(order):
        if assigned[start]:
            continue
        components += 1
        assigned[start] = True
        stack = [start]
        while stack:
            vertex = stack.pop()
            for neighbor in reverse[vertex]:
                if not assigned[neighbor]:
                    assigned[neighbor] = True
                    stack.append(neighbor)
    return components


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool) -> tuple[int, list[tuple[int, int]]] | None:
    if (input_is_null or not isinstance(values, (list, tuple))
            or len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)
                     or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    vertex_count, edge_count = values[:2]
    if not 1 <= vertex_count <= MAX_VERTICES or not 0 <= edge_count <= MAX_EDGES:
        return None
    if len(values) != 2 + 2 * edge_count:
        return None
    endpoints = values[2:]
    if any(not 0 <= endpoint < vertex_count for endpoint in endpoints):
        return None
    edges = [(endpoints[index], endpoints[index + 1])
             for index in range(0, len(endpoints), 2)]
    return vertex_count, edges


def validate_output(values: Sequence[int] | None, payload: bytes) -> bool:
    """Check any minimum-SCC orientation certificate, independent of its DFS order."""
    parsed = _parse(values, None, False)
    if parsed is None or not isinstance(payload, (bytes, bytearray)):
        return False
    vertex_count, edges = parsed
    if len(payload) != 8 * (len(edges) + 1):
        return False
    words = struct.unpack("<" + "q" * (len(edges) + 1), payload)
    component_count = _components(vertex_count, edges)
    bridge_count = sum(
        _components(vertex_count, edges, edge_id) > component_count
        for edge_id in range(len(edges))
    )
    if words[0] != component_count + bridge_count:
        return False
    directions = words[1:]
    if any(direction not in (-1, 1) for direction in directions):
        return False
    return _directed_component_count(vertex_count, edges, directions) == words[0]


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return INVALID_RESULT, b""
    vertex_count, edges = parsed
    component_count = _components(vertex_count, edges)
    bridge_count = sum(
        _components(vertex_count, edges, edge_id) > component_count
        for edge_id in range(len(edges))
    )
    directions = _directions(vertex_count, edges)
    minimum = component_count + bridge_count
    payload = struct.pack("<" + "q" * (len(edges) + 1), minimum, *directions)
    if not validate_output(values, payload):
        return INVALID_RESULT, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    if output_is_null or capacity is not None and capacity < len(payload):
        return INSUFFICIENT_CAPACITY_RESULT, b""
    return len(payload), payload
