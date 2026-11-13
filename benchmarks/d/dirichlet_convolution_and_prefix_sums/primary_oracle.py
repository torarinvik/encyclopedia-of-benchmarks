"""Grouped-prefix oracle for bounded Dirichlet convolution on Q_N."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MODULUS = 998244353
MAX_N = 64
MAX_QUOTIENT_COUNT = 15
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_QUOTIENT_COUNT
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * MAX_QUOTIENT_COUNT
WORKSPACE_BYTES = 1024


def quotient_values(n: int) -> list[int]:
    descending: list[int] = []
    left = 1
    while left <= n:
        quotient = n // left
        descending.append(quotient)
        left = n // quotient + 1
    return list(reversed(descending))


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool) -> tuple[list[int], list[int], list[int]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))):
        return None
    actual_length = len(values) if input_length is None else input_length
    if (type(actual_length) is not int or actual_length < 3
            or actual_length > MAX_PARSEABLE_INPUT_LENGTH
            or actual_length != len(values)):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    n = values[0]
    if not 1 <= n <= MAX_N:
        return None
    quotients = quotient_values(n)
    if actual_length != 1 + 2 * len(quotients):
        return None
    split = 1 + len(quotients)
    f_prefix = list(values[1:split])
    g_prefix = list(values[split:])
    if any(not 1 <= value < MODULUS for value in f_prefix + g_prefix):
        return None
    return quotients, f_prefix, g_prefix


def _prefix_at(prefix: dict[int, int], x: int) -> int:
    return 0 if x == 0 else prefix[x]


def _convolution_prefixes(quotients: list[int], f_values: list[int],
                          g_values: list[int]) -> list[int]:
    f_prefix = dict(zip(quotients, f_values, strict=True))
    g_prefix = dict(zip(quotients, g_values, strict=True))
    result: list[int] = []
    for x in quotients:
        total = 0
        left = 1
        while left <= x:
            quotient = x // left
            right = x // quotient
            lower_quotient = x // (quotient + 1)
            f_interval = (_prefix_at(f_prefix, right)
                          - _prefix_at(f_prefix, lower_quotient)) % MODULUS
            total = (total + f_interval * g_prefix[quotient]) % MODULUS
            left = right + 1
        result.append(total)
    return result


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return -1, b""
    quotients, f_prefix, g_prefix = parsed
    output_values = _convolution_prefixes(quotients, f_prefix, g_prefix)
    needed = 8 * len(output_values)
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0 or output_is_null or effective_capacity < needed):
        return -2, b""
    return needed, b"".join(struct.pack("<q", value) for value in output_values)
