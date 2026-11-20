"""Boolean-closure reference for a bounded DAG's transitive reduction."""

from __future__ import annotations

from collections.abc import Sequence

MIN_VERTICES = 1
MAX_VERTICES = 8
MAX_EDGES = MAX_VERTICES * (MAX_VERTICES - 1) // 2
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, tuple[int, ...], tuple[tuple[int, int], ...]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return None
    n, m = values[0], values[1]
    if not MIN_VERTICES <= n <= MAX_VERTICES or not 0 <= m <= MAX_EDGES:
        return None
    if input_length != 2 + 2 * m:
        return None
    outgoing = [0] * n
    arcs: list[tuple[int, int]] = []
    for edge in range(m):
        tail, head = values[2 + 2 * edge:4 + 2 * edge]
        if not 0 <= tail < n or not 0 <= head < n or tail == head:
            return None
        bit = 1 << head
        if outgoing[tail] & bit:
            return None
        outgoing[tail] |= bit
        arcs.append((tail, head))

    # Floyd closure is intentionally non-reflexive: only actual positive-length
    # paths are represented, allowing diagonal bits to detect directed cycles.
    reach = outgoing.copy()
    for middle in range(n):
        middle_bit = 1 << middle
        for source in range(n):
            if reach[source] & middle_bit:
                reach[source] |= reach[middle]
    if any(reach[vertex] & (1 << vertex) for vertex in range(n)):
        return None
    return n, tuple(outgoing), tuple(arcs)


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, outgoing, arcs = parsed
    reach = list(outgoing)
    for middle in range(n):
        middle_bit = 1 << middle
        for source in range(n):
            if reach[source] & middle_bit:
                reach[source] |= reach[middle]

    retained = 0
    for tail, head in arcs:
        redundant = False
        for middle in range(n):
            if (middle != tail and middle != head
                    and outgoing[tail] & (1 << middle)
                    and reach[middle] & (1 << head)):
                redundant = True
                break
        if not redundant:
            retained += 1
    return retained
