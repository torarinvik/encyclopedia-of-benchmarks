"""Direct vertex-subset checker for small maximum-clique instances."""

from __future__ import annotations

from collections.abc import Sequence

MAX_INDEPENDENT_VERTICES = 16
MAX_VERTICES = 24
MAX_PARSEABLE_INPUT_LENGTH = MAX_VERTICES + 2


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int | None:
    if (input_is_null or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)
                     or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1
    n = values[0]
    if not 0 <= n <= MAX_VERTICES or len(values) != n + 1:
        return -1
    rows = tuple(values[1:])
    domain = (1 << n) - 1
    if any(row < 0 or row & ~domain or row & (1 << vertex)
           for vertex, row in enumerate(rows)):
        return -1
    for left in range(n):
        for right in range(left + 1, n):
            if ((rows[left] >> right) & 1) != ((rows[right] >> left) & 1):
                return -1
    if n > MAX_INDEPENDENT_VERTICES:
        return None

    largest = 0
    for subset in range(1 << n):
        size = subset.bit_count()
        if size <= largest:
            continue
        vertices = subset
        valid = True
        while vertices:
            bit = vertices & -vertices
            vertex = bit.bit_length() - 1
            if (subset & ~bit) & ~rows[vertex]:
                valid = False
                break
            vertices ^= bit
        if valid:
            largest = size
    return largest
