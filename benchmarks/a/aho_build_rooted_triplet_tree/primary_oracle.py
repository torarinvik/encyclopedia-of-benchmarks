"""Clean-room adjacency/connected-components implementation of BUILD."""

from __future__ import annotations

import struct
from collections import deque
from collections.abc import Sequence

MAX_TAXA = 7
MAX_TRIPLETS = 105  # 3 orientations for each of C(7, 3) taxon sets.
MAX_VALID_INPUT_LENGTH = 2 + 3 * MAX_TRIPLETS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 112  # header plus at most 2*n-1 tree-node tokens.
WORKSPACE_BYTES = 8192
INVALID = -1
OUTPUT_ERROR = -2


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return None
    n, q = values[0], values[1]
    if not 1 <= n <= MAX_TAXA or not 0 <= q <= 3 * (n * (n - 1) * (n - 2) // 6):
        return None
    if len(values) != 2 + 3 * q:
        return None
    triples: list[tuple[int, int, int]] = []
    seen: set[tuple[int, int, int]] = set()
    for i in range(q):
        a, b, c = values[2 + 3 * i:5 + 3 * i]
        if (not 0 <= a < n or not 0 <= b < n or not 0 <= c < n
                or a == b or a == c or b == c):
            return None
        left, right = (a, b) if a < b else (b, a)
        key = (left, right, c)
        if key in seen:
            return None
        seen.add(key)
        triples.append(key)
    return n, triples


def _build(n: int, triples: list[tuple[int, int, int]]):
    """Return a leaf/internal tuple tree, or None when BUILD rejects R."""

    def visit(mask: int):
        vertices = [v for v in range(n) if mask & (1 << v)]
        if len(vertices) == 1:
            return ("leaf", vertices[0])

        adjacent = [[False] * n for _ in range(n)]
        for a, b, c in triples:
            if mask & (1 << a) and mask & (1 << b) and mask & (1 << c):
                adjacent[a][b] = True
                adjacent[b][a] = True

        seen = 0
        components: list[int] = []
        for start in vertices:
            if seen & (1 << start):
                continue
            component = 0
            queue = deque([start])
            seen |= 1 << start
            while queue:
                current = queue.popleft()
                component |= 1 << current
                for other in vertices:
                    if adjacent[current][other] and not seen & (1 << other):
                        seen |= 1 << other
                        queue.append(other)
            components.append(component)
        if len(components) == 1:
            return None

        # Components are discovered from their smallest member; this fixes a
        # serialization order without changing BUILD's unordered tree result.
        children = []
        for component in components:
            child = visit(component)
            if child is None:
                return None
            children.append(child)
        return ("node", tuple(children))

    return visit((1 << n) - 1)


def _serialize(tree) -> list[int]:
    tokens: list[int] = []

    def emit(node) -> None:
        if node[0] == "leaf":
            tokens.append(-(node[1] + 1))
            return
        children = node[1]
        tokens.append(len(children))
        for child in children:
            emit(child)

    emit(tree)
    return [len(tokens), *tokens]


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    """Return BUILD's canonical bounded tree or its incompatibility marker."""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID, b""
    n, triples = parsed
    tree = _build(n, triples)
    words = [0] if tree is None else _serialize(tree)
    payload = b"".join(struct.pack("<q", word) for word in words)
    if (type(output_is_null) is not bool or output_is_null
            or (capacity is not None
                and (type(capacity) is not int or capacity < len(payload)))):
        return OUTPUT_ERROR, b""
    return len(payload), payload

