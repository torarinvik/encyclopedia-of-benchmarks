"""Independent DSU-component formulation of the bounded BUILD recurrence."""

from __future__ import annotations

import struct
from collections.abc import Sequence

INVALID = -1
OUTPUT_ERROR = -2
MAX_PARSEABLE_INPUT_LENGTH = 318


def _read_frame(values: Sequence[int] | None, input_is_null: bool,
                input_length: int | None):
    """Validate the frame independently of the primary reference parser."""
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH):
        return None
    if any(type(word) is not int or word < -(1 << 63) or word >= (1 << 63)
           for word in values):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return None
    n, q = values[0], values[1]
    if not 1 <= n <= 7 or q < 0 or q > n * (n - 1) * (n - 2) // 2:
        return None
    if len(values) != 2 + 3 * q:
        return None
    triples: list[tuple[int, int, int]] = []
    seen: set[tuple[int, int, int]] = set()
    for offset in range(2, len(values), 3):
        first, second, outgroup = values[offset:offset + 3]
        if (not 0 <= first < n or not 0 <= second < n or not 0 <= outgroup < n
                or first == second or first == outgroup or second == outgroup):
            return None
        pair = sorted((first, second))
        key = (pair[0], pair[1], outgroup)
        if key in seen:
            return None
        seen.add(key)
        triples.append(key)
    return n, triples


def _build_by_union_find(n: int, triples: list[tuple[int, int, int]]):
    def visit(mask: int):
        members = [v for v in range(n) if mask & (1 << v)]
        if len(members) == 1:
            return ("leaf", members[0])

        parent = list(range(n))
        size = [1] * n

        def find(x: int) -> int:
            while parent[x] != x:
                parent[x] = parent[parent[x]]
                x = parent[x]
            return x

        def union(x: int, y: int) -> None:
            rx, ry = find(x), find(y)
            if rx == ry:
                return
            if size[rx] < size[ry]:
                rx, ry = ry, rx
            parent[ry] = rx
            size[rx] += size[ry]

        for a, b, c in triples:
            if mask & (1 << a) and mask & (1 << b) and mask & (1 << c):
                union(a, b)

        groups: dict[int, list[int]] = {}
        for vertex in members:
            groups.setdefault(find(vertex), []).append(vertex)
        components = sorted(groups.values(), key=lambda group: group[0])
        if len(components) == 1:
            return None
        children = []
        for group in components:
            child = visit(sum(1 << vertex for vertex in group))
            if child is None:
                return None
            children.append(child)
        return ("node", tuple(children))

    return visit((1 << n) - 1)


def _encode(tree) -> list[int]:
    words: list[int] = []

    def walk(node) -> None:
        if node[0] == "leaf":
            words.append(-node[1] - 1)
        else:
            words.append(len(node[1]))
            for child in node[1]:
                walk(child)

    walk(tree)
    return [len(words), *words]


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _read_frame(values, input_is_null, input_length)
    if parsed is None:
        return INVALID, b""
    n, triples = parsed
    tree = _build_by_union_find(n, triples)
    words = [0] if tree is None else _encode(tree)
    payload = b"".join(struct.pack("<q", word) for word in words)
    if (type(output_is_null) is not bool or output_is_null
            or (capacity is not None
                and (type(capacity) is not int or capacity < len(payload)))):
        return OUTPUT_ERROR, b""
    return len(payload), payload

