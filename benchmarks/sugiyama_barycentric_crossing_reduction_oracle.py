"""Primary exact oracle for the bounded Sugiyama barycentric profile."""

from __future__ import annotations

from collections.abc import Sequence
from fractions import Fraction

MAX_INPUT_WORDS = 299
MAX_OUTPUT_BYTES = 272
MAX_VERTICES = 32
MAX_LAYERS = 8
MAX_EDGES = 128


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_WORDS
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    layers, limit = values[:2]
    if not 2 <= layers <= MAX_LAYERS or not 0 <= limit <= 16:
        return None
    cursor = 2
    orders: list[list[int]] = []
    layer_of: dict[int, int] = {}
    for layer in range(layers):
        if cursor >= len(values):
            return None
        count = values[cursor]
        cursor += 1
        if count < 1 or count > MAX_VERTICES or cursor + count > len(values):
            return None
        row = list(values[cursor:cursor + count])
        cursor += count
        if any(not 0 <= vertex < MAX_VERTICES or vertex in layer_of for vertex in row):
            return None
        for vertex in row:
            layer_of[vertex] = layer
        orders.append(row)
    if sum(map(len, orders)) > MAX_VERTICES or cursor >= len(values):
        return None
    edge_count = values[cursor]
    cursor += 1
    if not 0 <= edge_count <= MAX_EDGES or cursor + 2 * edge_count != len(values):
        return None
    edges = []
    seen = set()
    for i in range(edge_count):
        u, v = values[cursor + 2 * i:cursor + 2 * i + 2]
        if (u not in layer_of or v not in layer_of or layer_of[v] != layer_of[u] + 1
                or (u, v) in seen):
            return None
        seen.add((u, v))
        edges.append((u, v))
    return orders, layer_of, edges, limit


def evaluate(values: Sequence[int] | None) -> tuple[int, bytes]:
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    orders, layer_of, edges, limit = parsed
    position: dict[int, int] = {}

    def update_positions(layer: int) -> None:
        for rank, vertex in enumerate(orders[layer]):
            position[vertex] = rank

    def reorder(target: int, fixed: int, downward: bool) -> bool:
        update_positions(fixed)
        old = orders[target]
        rank = {vertex: i for i, vertex in enumerate(old)}
        neighbors = {vertex: [] for vertex in old}
        for u, v in edges:
            if downward and layer_of[u] == fixed and layer_of[v] == target:
                neighbors[v].append(position[u])
            elif not downward and layer_of[u] == target and layer_of[v] == fixed:
                neighbors[u].append(position[v])
        barycenter = {
            vertex: Fraction(sum(neighbors[vertex]), len(neighbors[vertex]))
            if neighbors[vertex] else Fraction(rank[vertex], 1)
            for vertex in old
        }
        new = sorted(old, key=lambda vertex: (barycenter[vertex], rank[vertex]))
        changed = new != old
        orders[target] = new
        update_positions(target)
        return changed

    sweeps = 0
    for _ in range(limit):
        before = [row[:] for row in orders]
        for layer in range(len(orders) - 1):
            reorder(layer + 1, layer, True)
        for layer in range(len(orders) - 2, -1, -1):
            reorder(layer, layer + 1, False)
        sweeps += 1
        if orders == before:
            break

    for layer in range(len(orders)):
        update_positions(layer)
    crossings = 0
    for layer in range(len(orders) - 1):
        lane_edges = [(u, v) for u, v in edges if layer_of[u] == layer]
        for i, (u1, v1) in enumerate(lane_edges):
            for u2, v2 in lane_edges[i + 1:]:
                if (position[u1] - position[u2]) * (position[v1] - position[v2]) < 0:
                    crossings += 1
    words = [sweeps, crossings, *(vertex for row in orders for vertex in row)]
    raw = b"".join(word.to_bytes(8, "little", signed=True) for word in words)
    return len(raw), raw


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_WORDS)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    result, raw = evaluate(values)
    if result < 0:
        return result, raw
    if output_is_null or capacity is not None and capacity < len(raw):
        return -2, b""
    return result, raw
