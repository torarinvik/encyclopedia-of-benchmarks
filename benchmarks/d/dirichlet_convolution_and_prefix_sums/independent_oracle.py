"""Symmetric g-block oracle for Dirichlet-convolution prefix values."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MODULUS = 998244353
MAX_N = 64
MAX_QUOTIENT_COUNT = 15
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_QUOTIENT_COUNT
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * MAX_QUOTIENT_COUNT


def _ordered_floor_set(n: int) -> list[int]:
    return sorted({n // divisor for divisor in range(1, n + 1)})


def _decode(values: Sequence[int] | None, input_length: int | None,
            input_is_null: bool) -> tuple[list[int], dict[int, int], dict[int, int]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))):
        return None
    length = len(values) if input_length is None else input_length
    if (type(length) is not int or length < 3 or length > MAX_PARSEABLE_INPUT_LENGTH
            or length != len(values)):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    n = values[0]
    if n < 1 or n > MAX_N:
        return None
    points = _ordered_floor_set(n)
    if length != 1 + 2 * len(points):
        return None
    middle = 1 + len(points)
    f_at = dict(zip(points, values[1:middle]))
    g_at = dict(zip(points, values[middle:]))
    if any(value < 1 or value >= MODULUS for value in (*f_at.values(), *g_at.values())):
        return None
    return points, f_at, g_at


def _g_prefix_at(g_at: dict[int, int], x: int) -> int:
    return 0 if x == 0 else g_at[x]


def _by_g_intervals(points: list[int], f_at: dict[int, int],
                    g_at: dict[int, int]) -> list[int]:
    outputs = []
    for limit in points:
        subtotal = 0
        first_j = 1
        while first_j <= limit:
            f_value = limit // first_j
            last_j = limit // f_value
            before = limit // (f_value + 1)
            count_of_g = (_g_prefix_at(g_at, last_j)
                          - _g_prefix_at(g_at, before)) % MODULUS
            subtotal = (subtotal + count_of_g * f_at[f_value]) % MODULUS
            first_j = last_j + 1
        outputs.append(subtotal)
    return outputs


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _decode(values, input_length, input_is_null)
    if parsed is None:
        return -1, b""
    points, f_at, g_at = parsed
    residues = _by_g_intervals(points, f_at, g_at)
    required = 8 * len(residues)
    actual_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(actual_capacity) is not int
            or actual_capacity < 0 or output_is_null or actual_capacity < required):
        return -2, b""
    return required, b"".join(struct.pack("<q", value) for value in residues)
