"""Reverse-point DFS oracle for the DOI 735 permutation family tree."""

from __future__ import annotations

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


def _reverse_point(permutation: tuple[int, ...] | list[int]) -> int:
    for index in range(len(permutation) - 1):
        if permutation[index] > permutation[index + 1]:
            return index + 1
    return len(permutation)


def _enumerate(permutation: list[int], output: list[int]) -> None:
    output.extend(permutation)
    n = len(permutation)
    reverse_point = _reverse_point(permutation)

    for child_position in range(1, reverse_point):
        left = child_position - 1
        permutation[left], permutation[left + 1] = permutation[left + 1], permutation[left]
        _enumerate(permutation, output)
        permutation[left], permutation[left + 1] = permutation[left + 1], permutation[left]

    if (reverse_point + 2 <= n
            and permutation[reverse_point - 1] < permutation[reverse_point + 1]):
        left = reverse_point
        permutation[left], permutation[left + 1] = permutation[left + 1], permutation[left]
        _enumerate(permutation, output)
        permutation[left], permutation[left + 1] = permutation[left + 1], permutation[left]


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
    words = [math.factorial(n)]
    _enumerate(list(range(1, n + 1)), words)
    payload = struct.pack("<" + "q" * len(words), *words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
