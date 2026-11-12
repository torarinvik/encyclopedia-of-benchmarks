"""Direct variable-to-factor assignment oracle for power projections."""

from __future__ import annotations

from collections.abc import Sequence
from itertools import product
import struct

try:
    from .primary_oracle import (
        I64_MAX, I64_MIN, INVALID, MAX_INPUT_LENGTH, MAX_M, MAX_N,
        MODULUS, OUTPUT_ERROR,
    )
except ImportError:  # Direct invocation from this package directory.
    from primary_oracle import (
        I64_MAX, I64_MIN, INVALID, MAX_INPUT_LENGTH, MAX_M, MAX_N,
        MODULUS, OUTPUT_ERROR,
    )


def _projection(
    power: int, n: int, series: list[int], weights: list[int]
) -> int:
    total = 0
    # Every variable is either absent from the union or belongs to exactly
    # one of the ordered factors of s^power.
    for assignment in product(range(power + 1), repeat=n):
        factor_masks = [0] * power
        union_mask = 0
        for variable, factor in enumerate(assignment):
            if factor < power:
                bit = 1 << variable
                factor_masks[factor] |= bit
                union_mask |= bit
        coefficient = 1
        for mask in factor_masks:
            coefficient = coefficient * series[mask] % MODULUS
        total = (total + weights[union_mask] * coefficient) % MODULUS
    return total


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID, b""
    if len(values) < 2 or len(values) > MAX_INPUT_LENGTH:
        return INVALID, b""
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return INVALID, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID, b""
    n, powers = values[:2]
    if not 0 <= n <= MAX_N or not 0 <= powers <= MAX_M:
        return INVALID, b""
    size = 1 << n
    if len(values) != 2 + 2 * size:
        return INVALID, b""
    series = list(values[2:2 + size])
    weights = list(values[2 + size:])
    if any(not 0 <= coefficient < MODULUS for coefficient in series + weights):
        return INVALID, b""

    byte_count = 8 * powers
    if output_is_null or (
        output_capacity is not None
        and (type(output_capacity) is not int or output_capacity < byte_count)
    ):
        return OUTPUT_ERROR, b""
    answers = [_projection(power, n, series, weights) for power in range(powers)]
    return byte_count, b"".join(struct.pack("<q", answer) for answer in answers)
