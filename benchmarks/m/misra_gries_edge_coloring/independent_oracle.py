"""Independent edge-color certificate checks for the bounded Vizing profile."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VERTICES = 6
MAX_EDGES = 6
MAX_PARSEABLE_INPUT_LENGTH = 15
SIGNATURE_BASE = 8 ** 6
INVALID_RESULT = -1


def _read_graph(values: Sequence[int] | None, input_is_null: bool,
                input_length: int | None) -> tuple[int, list[tuple[int, int]]] | None:
    if input_is_null is not False or not isinstance(values, (list, tuple)):
        return None
    if len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    declared = len(values) if input_length is None else input_length
    if type(declared) is not int or declared != len(values):
        return None
    vertex_count, edge_count = values[0], values[1]
    if vertex_count not in range(1, MAX_VERTICES + 1) or edge_count not in range(MAX_EDGES + 1):
        return None
    if len(values) != 2 + 2 * edge_count:
        return None
    pairs: list[tuple[int, int]] = []
    known: set[tuple[int, int]] = set()
    for i in range(edge_count):
        a, b = values[2 + 2 * i:4 + 2 * i]
        if a not in range(vertex_count) or b not in range(vertex_count) or a == b:
            return None
        pair = (a, b) if a < b else (b, a)
        if pair in known:
            return None
        known.add(pair)
        pairs.append(pair)
    return vertex_count, pairs


def verify_result(values: Sequence[int] | None, result: int,
                  input_is_null: bool = False,
                  input_length: int | None = None) -> bool:
    """Check the result's palette and coloring certificate without fan logic."""
    graph = _read_graph(values, input_is_null, input_length)
    if graph is None:
        return result == INVALID_RESULT
    if type(result) is not int or result < 0:
        return False
    vertices, edges = graph
    degree = [0] * vertices
    for left, right in edges:
        degree[left] += 1
        degree[right] += 1
    required_palette = max(degree, default=0) + 1 if edges else 0
    if result >= (required_palette + 1) * SIGNATURE_BASE:
        return False
    palette = result // SIGNATURE_BASE
    signature = result % SIGNATURE_BASE
    if palette != required_palette:
        return False
    incident: list[set[int]] = [set() for _ in range(vertices)]
    for edge_id, (left, right) in enumerate(edges):
        color = (signature >> (3 * edge_id)) & 7
        if color >= palette or color in incident[left] or color in incident[right]:
            return False
        incident[left].add(color)
        incident[right].add(color)
    return True
