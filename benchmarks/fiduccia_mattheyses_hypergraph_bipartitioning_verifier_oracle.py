"""Independent FM replay using complete cut recounts for every candidate."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VERTICES = 8
MAX_NETS = 12
MAX_VALID_INPUT_LENGTH = 3 + MAX_NETS * (1 + MAX_VERTICES)
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> tuple[int, int, list[list[int]]] | None:
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return None
    size = len(values) if input_length is None else input_length
    if type(size) is not int or size < 3 or size > MAX_PARSEABLE_INPUT_LENGTH or size != len(values):
        return None
    for item in values:
        if type(item) is not int or not -(1 << 63) <= item < (1 << 63):
            return None
    n, m, mask = values[0], values[1], values[2]
    if (not 4 <= n <= MAX_VERTICES or n % 2 or not 0 <= m <= MAX_NETS
            or not 0 <= mask < (1 << n) or mask.bit_count() != n // 2):
        return None
    edges: list[list[int]] = []
    cursor = 3
    for _ in range(m):
        if cursor >= size:
            return None
        count = values[cursor]
        cursor += 1
        if not 2 <= count <= n or cursor + count > size:
            return None
        edge = list(values[cursor:cursor + count])
        cursor += count
        if any(x < 0 or x >= n for x in edge) or edge != sorted(set(edge)):
            return None
        edges.append(edge)
    if cursor != size or size > MAX_VALID_INPUT_LENGTH:
        return None
    return n, mask, edges


def _count_cut_nets(mask: int, edges: list[list[int]]) -> int:
    result = 0
    for edge in edges:
        first_side = bool(mask & (1 << edge[0]))
        if any(bool(mask & (1 << vertex)) != first_side for vertex in edge[1:]):
            result += 1
    return result


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return INVALID_RESULT
    n, mask, edges = decoded
    midpoint = n // 2

    while True:
        original_mask = mask
        original_cut = _count_cut_nets(mask, edges)
        minimum_cut = original_cut
        earliest_minimum_mask = mask
        locked = [0] * n

        while True:
            count_a = mask.bit_count()
            candidates: list[tuple[int, int, int, int]] = []
            current_cut = _count_cut_nets(mask, edges)
            for vertex in range(n):
                if locked[vertex]:
                    continue
                next_count = count_a + (1 if not mask & (1 << vertex) else -1)
                if next_count < midpoint - 1 or next_count > midpoint + 1:
                    continue
                changed = mask ^ (1 << vertex)
                candidate_cut = _count_cut_nets(changed, edges)
                gain = current_cut - candidate_cut
                imbalance = abs(2 * next_count - n)
                candidates.append((-gain, imbalance, vertex, changed))
            if not candidates:
                break
            _, _, selected, mask = min(candidates)
            locked[selected] = 1
            resulting_cut = _count_cut_nets(mask, edges)
            if resulting_cut < minimum_cut:
                minimum_cut = resulting_cut
                earliest_minimum_mask = mask

        if minimum_cut >= original_cut:
            return (original_cut << 8) | original_mask
        mask = earliest_minimum_mask
