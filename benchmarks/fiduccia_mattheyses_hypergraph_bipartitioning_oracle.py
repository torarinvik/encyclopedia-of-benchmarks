"""Directly rescored FM passes for bounded hypergraph bipartitioning."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VERTICES = 8
MAX_NETS = 12
MAX_VALID_INPUT_LENGTH = 3 + MAX_NETS * (1 + MAX_VERTICES)
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_RESULT = (MAX_NETS << 8) | ((1 << MAX_VERTICES) - 1)
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int, tuple[tuple[int, ...], ...]] | None:
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return None
    length = len(values) if input_length is None else input_length
    if (type(length) is not int or length < 3 or length > MAX_PARSEABLE_INPUT_LENGTH
            or length != len(values)):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None

    vertex_count, net_count, initial_mask = values[:3]
    if (type(vertex_count) is not int or vertex_count < 4 or vertex_count > MAX_VERTICES
            or vertex_count % 2 != 0 or type(net_count) is not int
            or not 0 <= net_count <= MAX_NETS or type(initial_mask) is not int
            or not 0 <= initial_mask < (1 << vertex_count)
            or initial_mask.bit_count() != vertex_count // 2):
        return None

    offset = 3
    nets: list[tuple[int, ...]] = []
    for _ in range(net_count):
        if offset >= length:
            return None
        degree = values[offset]
        offset += 1
        if type(degree) is not int or not 2 <= degree <= vertex_count or offset + degree > length:
            return None
        vertices = tuple(values[offset:offset + degree])
        offset += degree
        if (any(type(vertex) is not int or not 0 <= vertex < vertex_count for vertex in vertices)
                or any(vertices[index - 1] >= vertices[index] for index in range(1, degree))):
            return None
        nets.append(vertices)
    if offset != length or length > MAX_VALID_INPUT_LENGTH:
        return None
    return vertex_count, initial_mask, tuple(nets)


def _cut_count(mask: int, nets: tuple[tuple[int, ...], ...]) -> int:
    cut = 0
    for net in nets:
        in_a = any(mask & (1 << vertex) for vertex in net)
        in_b = any(not mask & (1 << vertex) for vertex in net)
        cut += int(in_a and in_b)
    return cut


def _gain(vertex: int, mask: int, nets: tuple[tuple[int, ...], ...]) -> int:
    """Count each incident net's cut-count change by scanning its vertices."""
    in_a = bool(mask & (1 << vertex))
    gain = 0
    for net in nets:
        if vertex not in net:
            continue
        a_count = sum(bool(mask & (1 << member)) for member in net)
        b_count = len(net) - a_count
        if in_a:
            if a_count == 1 and b_count > 0:
                gain += 1
            elif a_count > 1 and b_count == 0:
                gain -= 1
        else:
            if b_count == 1 and a_count > 0:
                gain += 1
            elif b_count > 1 and a_count == 0:
                gain -= 1
    return gain


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    vertex_count, mask, nets = parsed
    half = vertex_count // 2

    while True:
        pass_start_mask = mask
        pass_start_cut = _cut_count(mask, nets)
        best_mask = mask
        best_cut = pass_start_cut
        locked = [False] * vertex_count

        while True:
            a_size = mask.bit_count()
            best_vertex = -1
            best_gain: int | None = None
            best_imbalance: int | None = None
            for vertex in range(vertex_count):
                if locked[vertex]:
                    continue
                next_size = a_size - 1 if mask & (1 << vertex) else a_size + 1
                if not half - 1 <= next_size <= half + 1:
                    continue
                candidate_gain = _gain(vertex, mask, nets)
                candidate_imbalance = abs(2 * next_size - vertex_count)
                if (best_gain is None or candidate_gain > best_gain
                        or (candidate_gain == best_gain
                            and (candidate_imbalance < best_imbalance
                                 or (candidate_imbalance == best_imbalance
                                     and vertex < best_vertex)))):
                    best_vertex = vertex
                    best_gain = candidate_gain
                    best_imbalance = candidate_imbalance
            if best_vertex < 0:
                break

            locked[best_vertex] = True
            mask ^= 1 << best_vertex
            current_cut = _cut_count(mask, nets)
            # Strict comparison preserves the earliest prefix attaining a minimum.
            if current_cut < best_cut:
                best_cut = current_cut
                best_mask = mask

        if best_cut >= pass_start_cut:
            return (pass_start_cut << 8) | pass_start_mask
        mask = best_mask
