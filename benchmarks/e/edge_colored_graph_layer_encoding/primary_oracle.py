"""Primary bit-matrix reference for edge-color layer encoding."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_M = 28
MAX_D = 3
MAX_Q = 3
MAX_VALID_INPUT_LENGTH = 4 + MAX_N + 3 * MAX_M
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 1808
WORKSPACE_BYTES = 4096


def _parse(values: Sequence[int]):
    if len(values) < 4 + 1 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    n, m, layers, vertex_color_count = values[:4]
    if (not 1 <= n <= MAX_N or not 0 <= m <= MAX_M
            or not 1 <= layers <= MAX_D or not 1 <= vertex_color_count <= MAX_Q):
        return None
    fixed_length = 4 + n
    if len(values) < fixed_length or any(
            not 0 <= color < vertex_color_count
            for color in values[4:fixed_length]):
        return None
    if len(values) != fixed_length + 3 * m:
        return None
    vertex_colors = tuple(values[4:fixed_length])
    masks = [[0] * MAX_N for _ in range(MAX_N)]
    offset = fixed_length
    for _ in range(m):
        u, v, color = values[offset:offset + 3]
        offset += 3
        if (not 0 <= u < n or not 0 <= v < n or u == v
                or not 1 <= color < (1 << layers)):
            return None
        if u > v:
            u, v = v, u
        if masks[u][v]:
            return None
        masks[u][v] = color
    return n, layers, vertex_color_count, vertex_colors, masks


def _encode(n: int, layers: int, color_count: int,
            vertex_colors: Sequence[int], masks: Sequence[Sequence[int]]) -> bytes:
    node_count = n * layers
    edges: list[tuple[int, int]] = []
    for layer in range(layers):
        bit = 1 << layer
        for u in range(n):
            for v in range(u + 1, n):
                if masks[u][v] & bit:
                    edges.append((layer * n + u, layer * n + v))
    for vertex in range(n):
        for layer in range(layers - 1):
            edges.append((layer * n + vertex, (layer + 1) * n + vertex))
    edges.sort()
    words = [node_count, len(edges)]
    words.extend(layer * color_count + vertex_colors[vertex]
                 for layer in range(layers) for vertex in range(n))
    for edge in edges:
        words.extend(edge)
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
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    payload = _encode(*parsed)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload


def expected_result(values: Sequence[int] | None) -> int:
    return expected_output(values)[0]
