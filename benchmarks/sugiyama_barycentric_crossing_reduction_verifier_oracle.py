"""Independent exact verifier oracle for the bounded Sugiyama profile."""

from __future__ import annotations

from collections.abc import Sequence
from fractions import Fraction

MAX_INPUT_WORDS = 299


def _read(values: Sequence[int] | None):
    if not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_WORDS:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    layer_count, max_sweeps = values[0], values[1]
    if not 2 <= layer_count <= 8 or not 0 <= max_sweeps <= 16:
        return None
    at = 2
    layers: list[list[int]] = []
    owner: dict[int, int] = {}
    for level in range(layer_count):
        if at == len(values):
            return None
        width = values[at]
        at += 1
        if width < 1 or at + width > len(values):
            return None
        ids = list(values[at:at + width])
        at += width
        for ident in ids:
            if ident < 0 or ident >= 32 or ident in owner:
                return None
            owner[ident] = level
        layers.append(ids)
    if len(owner) > 32 or at == len(values):
        return None
    count = values[at]
    at += 1
    if not 0 <= count <= 128 or at + 2 * count != len(values):
        return None
    arcs: list[tuple[int, int]] = []
    arc_set: set[tuple[int, int]] = set()
    for pair in range(count):
        arc = (values[at + 2 * pair], values[at + 2 * pair + 1])
        if (arc[0] not in owner or arc[1] not in owner
                or owner[arc[1]] != owner[arc[0]] + 1 or arc in arc_set):
            return None
        arc_set.add(arc)
        arcs.append(arc)
    return layers, owner, arcs, max_sweeps


def _oracle(values: Sequence[int] | None) -> tuple[int, bytes]:
    parsed = _read(values)
    if parsed is None:
        return -1, b""
    layers, owner, arcs, max_sweeps = parsed
    rounds = 0
    for _ in range(max_sweeps):
        previous = tuple(tuple(layer) for layer in layers)
        for level in range(1, len(layers)):
            upper = {v: i for i, v in enumerate(layers[level - 1])}
            current = layers[level]
            old_pos = {v: i for i, v in enumerate(current)}
            ordered = []
            for v in current:
                adjacent = [upper[u] for u, w in arcs if w == v and owner[u] == level - 1]
                if adjacent:
                    key = (sum(adjacent), len(adjacent))
                else:
                    key = (old_pos[v], 1)
                ordered.append((v, key))
            ordered.sort(key=lambda item: (Fraction(*item[1]), old_pos[item[0]]))
            layers[level] = [item[0] for item in ordered]
        for level in range(len(layers) - 2, -1, -1):
            lower = {v: i for i, v in enumerate(layers[level + 1])}
            current = layers[level]
            old_pos = {v: i for i, v in enumerate(current)}
            ordered = []
            for v in current:
                adjacent = [lower[w] for u, w in arcs if u == v and owner[w] == level + 1]
                if adjacent:
                    key = (sum(adjacent), len(adjacent))
                else:
                    key = (old_pos[v], 1)
                ordered.append((v, key))
            ordered.sort(key=lambda item: (Fraction(*item[1]), old_pos[item[0]]))
            layers[level] = [item[0] for item in ordered]
        rounds += 1
        if tuple(tuple(layer) for layer in layers) == previous:
            break
    pos: dict[int, int] = {}
    for layer in layers:
        pos.update({vertex: index for index, vertex in enumerate(layer)})
    crossings = sum(
        1
        for i, (u, v) in enumerate(arcs)
        for x, y in arcs[i + 1:]
        if owner[u] == owner[x] and (pos[u] - pos[x]) * (pos[v] - pos[y]) < 0
    )
    output_words = [rounds, crossings, *(vertex for layer in layers for vertex in layer)]
    raw = b"".join(x.to_bytes(8, "little", signed=True) for x in output_words)
    return len(raw), raw


def verify(values: Sequence[int] | None, actual_length: int, actual_output: bytes,
           capacity: int | None = None, output_is_null: bool = False,
           input_is_null: bool = False, input_length: int | None = None) -> bool:
    if (type(actual_length) is not int or actual_length < 0 or not isinstance(actual_output, bytes)
            or type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_WORDS)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return False
    if input_is_null or values is None:
        return actual_length == -1 and actual_output == b""
    expected_length, expected = _oracle(values)
    if expected_length < 0:
        return actual_length == expected_length and actual_output == expected
    if output_is_null or capacity is not None and capacity < expected_length:
        return actual_length == -2 and actual_output == b""
    return actual_length == expected_length and actual_output[:actual_length] == expected
