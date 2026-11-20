"""Independent bitset/stack reference and certificate checker."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_VERTICES = 32
MAX_EDGES = 128
MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES + 1
MAX_OUTPUT_BYTES = 33


def _read_graph(words: Sequence[int] | None) -> tuple[int, list[int]] | None:
    if (not isinstance(words, (list, tuple)) or not 2 <= len(words) <= MAX_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in words)):
        return None
    n, edge_count = words[0], words[1]
    if not 0 <= n <= MAX_VERTICES or not 0 <= edge_count <= MAX_EDGES:
        return None
    if len(words) != 2 + 2 * edge_count:
        return None
    masks = [0] * n
    for edge_index in range(edge_count):
        u, v = words[2 + 2 * edge_index:4 + 2 * edge_index]
        if u < 0 or v <= u or v >= n or (masks[u] >> v) & 1:
            return None
        masks[u] |= 1 << v
        masks[v] |= 1 << u
    return n, masks


def _reference(n: int, masks: list[int]) -> bytes | None:
    remaining = (1 << n) - 1
    color = [0] * n
    threshold = 0
    while (threshold + 1) ** 2 <= n:
        threshold += 1
    first_palette_color = 1

    while remaining:
        selected = -1
        degree_max = -1
        for v in range(n):
            if not (remaining >> v) & 1:
                continue
            degree = (masks[v] & remaining).bit_count()
            if degree > degree_max:
                selected, degree_max = v, degree
        if degree_max < threshold:
            break

        neighborhood = masks[selected] & remaining
        side = [-1] * n
        # Repeated stack traversals orient each component from its smallest ID.
        for root in range(n):
            if not (neighborhood >> root) & 1 or side[root] != -1:
                continue
            side[root] = 0
            stack = [root]
            while stack:
                u = stack.pop()
                neighbors = masks[u] & neighborhood
                for v in range(n - 1, -1, -1):
                    if not (neighbors >> v) & 1:
                        continue
                    if side[v] == -1:
                        side[v] = side[u] ^ 1
                        stack.append(v)
                    elif side[v] == side[u]:
                        return None
        for v in range(n):
            if (neighborhood >> v) & 1:
                color[v] = first_palette_color + side[v]
        color[selected] = first_palette_color + 2
        remaining &= ~(neighborhood | (1 << selected))
        first_palette_color += 2

    for v in range(n):
        if not (remaining >> v) & 1:
            continue
        forbidden = set()
        for u in range(n):
            if (masks[v] >> u) & 1 and color[u]:
                forbidden.add(color[u])
        candidate = first_palette_color
        while candidate in forbidden:
            candidate += 1
        color[v] = candidate

    return bytes([max(color, default=0), *color])


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None
            and not isinstance(values, (list, tuple))
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _read_graph(values)
    if parsed is None:
        return -1, b""
    n, masks = parsed
    encoded = _reference(n, masks)
    if encoded is None:
        return -1, b""
    allowed = MAX_OUTPUT_BYTES if capacity is None else capacity
    if output_is_null or allowed < len(encoded):
        return -2, b""
    return len(encoded), encoded


def validate_coloring(values: Sequence[int], output: bytes) -> bool:
    parsed = _read_graph(values)
    if parsed is None or len(output) != parsed[0] + 1:
        return False
    n, masks = parsed
    palette = output[0]
    colors = output[1:]
    if any(color == 0 or color > palette for color in colors):
        return n == 0 and palette == 0 and not colors
    return all(not (masks[v] >> u) & 1 or colors[v] != colors[u]
               for v in range(n) for u in range(n)) and palette == max(colors, default=0)
