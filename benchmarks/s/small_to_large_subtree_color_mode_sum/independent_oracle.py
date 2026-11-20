"""Direct ancestor-chain frequency oracle, independent of map merging."""

from __future__ import annotations

import struct
from collections import Counter
from collections.abc import Sequence

MAX_VERTICES = 64
MAX_INPUT_LENGTH = 129
MAX_OUTPUT_BYTES = 8 * MAX_VERTICES


def _read(values: Sequence[int] | None, input_length: int | None,
          input_is_null: bool) -> tuple[int, list[int], list[int]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) < 2 or len(values) > MAX_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    n = values[0]
    if n < 1 or n > MAX_VERTICES or len(values) != n * 2:
        return None
    parents = [-1] + [int(values[v]) for v in range(1, n)]
    for vertex in range(1, n):
        if parents[vertex] < 0 or parents[vertex] >= vertex:
            return None
    labels = [int(color) for color in values[n:]]
    if any(label < -1000 or label > 1000 for label in labels):
        return None
    return n, parents, labels


def _by_ancestor_chains(n: int, parent: list[int], colors: list[int]) -> list[int]:
    answers = []
    for root in range(n):
        counts: Counter[int] = Counter()
        for candidate in range(n):
            ancestor = candidate
            while ancestor != root and ancestor >= 0:
                ancestor = parent[ancestor]
            if ancestor == root:
                counts[colors[candidate]] += 1
        top = max(counts.values())
        answers.append(sum(color for color, amount in counts.items() if amount == top))
    return answers


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    decoded = _read(values, input_length, input_is_null)
    if decoded is None:
        return -1, b""
    n, parent, colors = decoded
    result = _by_ancestor_chains(n, parent, colors)
    raw = b"".join(struct.pack("<q", value) for value in result)
    limit = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(limit) is not int or limit < 0):
        return -2, b""
    if output_is_null or len(raw) > limit:
        return -2, b""
    return len(raw), raw
