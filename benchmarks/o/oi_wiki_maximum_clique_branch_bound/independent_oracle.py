"""Exhaustive vertex-subset reference for small maximum-clique fixtures."""

from __future__ import annotations

from typing import Sequence

try:
    from .primary_oracle import MAX_VERTICES, MAX_PARSEABLE_INPUT_LENGTH
except ImportError:  # Direct invocation from the package directory.
    from primary_oracle import MAX_VERTICES, MAX_PARSEABLE_INPUT_LENGTH  # type: ignore[no-redef]

MAX_INDEPENDENT_VERTICES = 16


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int | None:
    """Return -1 for malformed frames, None above the exhaustive bound."""
    if (input_is_null or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)
                     or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1
    n = values[0]
    if not 0 <= n <= MAX_VERTICES or len(values) != 1 + n:
        return -1
    adjacency = list(values[1:])
    domain_mask = (1 << n) - 1
    if any(mask < 0 or mask & ~domain_mask for mask in adjacency):
        return -1
    for vertex, mask in enumerate(adjacency):
        if mask & (1 << vertex):
            return -1
    for left in range(n):
        for right in range(left + 1, n):
            if bool(adjacency[left] & (1 << right)) != bool(adjacency[right] & (1 << left)):
                return -1
    if n > MAX_INDEPENDENT_VERTICES:
        return None

    best = 0
    for subset in range(1 << n):
        size = subset.bit_count()
        if size <= best:
            continue
        vertices = subset
        clique = True
        while vertices:
            bit = vertices & -vertices
            vertex = bit.bit_length() - 1
            others = subset & ~bit
            if others & ~adjacency[vertex]:
                clique = False
                break
            vertices &= ~bit
        if clique:
            best = size
    return best
