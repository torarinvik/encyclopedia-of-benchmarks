"""Parent-map verifier for DOI 735 permutation reverse search."""

from __future__ import annotations

import itertools
import math
import struct
from collections.abc import Sequence

MAX_N = 4
MAX_INPUT = 2
MAX_OUTPUT_BYTES = 776


def _parse(values: Sequence[int] | None) -> int | None:
    if not isinstance(values, (tuple, list)) or len(values) != 1:
        return None
    n = values[0]
    if type(n) is not int or not 1 <= n <= MAX_N:
        return None
    return n


def _parent(permutation: tuple[int, ...]) -> tuple[int, ...] | None:
    for index in range(len(permutation) - 1):
        if permutation[index] > permutation[index + 1]:
            parent = list(permutation)
            parent[index], parent[index + 1] = parent[index + 1], parent[index]
            return tuple(parent)
    return None


def _child_position(parent: tuple[int, ...], child: tuple[int, ...]) -> int:
    for index, (left, right) in enumerate(zip(parent, child)):
        if left != right:
            return index + 1
    return len(parent)


def _enumerate(parent: tuple[int, ...], candidates: tuple[tuple[int, ...], ...],
               output: list[int]) -> None:
    output.extend(parent)
    children = [candidate for candidate in candidates if _parent(candidate) == parent]
    children.sort(key=lambda candidate: _child_position(parent, candidate))
    for child in children:
        _enumerate(child, candidates, output)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    n = _parse(values)
    if n is None:
        return -1, b""
    candidates = tuple(itertools.permutations(range(1, n + 1)))
    flattened = [math.factorial(n)]
    _enumerate(tuple(range(1, n + 1)), candidates, flattened)
    payload = struct.pack("<" + "q" * len(flattened), *flattened)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
