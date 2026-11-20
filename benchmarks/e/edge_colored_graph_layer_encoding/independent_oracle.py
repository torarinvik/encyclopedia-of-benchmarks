"""Independent edge-list expansion reference for layered graph encoding."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_VALID_INPUT_LENGTH = 96
MAX_PARSEABLE_INPUT_LENGTH = 97
MAX_OUTPUT_BYTES = 1808


def _read(values: Sequence[int]):
    if len(values) < 5 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    n, edge_count, layer_count, class_count = values[:4]
    if not (1 <= n <= 8 and 0 <= edge_count <= 28
            and 1 <= layer_count <= 3 and 1 <= class_count <= 3):
        return None
    color_end = 4 + n
    if len(values) != color_end + 3 * edge_count:
        return None
    source_colors = values[4:color_end]
    if any(color < 0 or color >= class_count for color in source_colors):
        return None
    source_edges: set[tuple[int, int, int]] = set()
    endpoint_pairs: set[tuple[int, int]] = set()
    for offset in range(color_end, len(values), 3):
        left, right, color = values[offset:offset + 3]
        if (left < 0 or left >= n or right < 0 or right >= n or left == right
                or color < 1 or color >= (1 << layer_count)):
            return None
        if left > right:
            left, right = right, left
        pair = (left, right)
        if pair in endpoint_pairs:
            return None
        endpoint_pairs.add(pair)
        edge = (left, right, color)
        source_edges.add(edge)
    return n, edge_count, layer_count, class_count, source_colors, source_edges


def _encode(n: int, layer_count: int, class_count: int,
            source_colors: Sequence[int], source_edges: set[tuple[int, int, int]]) -> bytes:
    transformed: set[tuple[int, int]] = set()
    for left, right, color in source_edges:
        for layer in range(layer_count):
            if color & (1 << layer):
                transformed.add((layer * n + left, layer * n + right))
    for vertex in range(n):
        for layer in range(layer_count - 1):
            transformed.add((layer * n + vertex, (layer + 1) * n + vertex))
    ordered_edges = sorted(transformed)
    colors = [layer * class_count + source_colors[vertex]
              for layer in range(layer_count) for vertex in range(n)]
    words = [n * layer_count, len(ordered_edges), *colors]
    for left, right in ordered_edges:
        words.extend((left, right))
    return struct.pack("<" + "q" * len(words), *words)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or input_length < 0)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and not isinstance(values, (list, tuple))
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    parsed = _read(values)
    if parsed is None:
        return -1, b""
    n, edge_count, layer_count, class_count, source_colors, source_edges = parsed
    payload = _encode(n, layer_count, class_count, source_colors, source_edges)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload


def expected_result(values: Sequence[int] | None) -> int:
    return expected_output(values)[0]
