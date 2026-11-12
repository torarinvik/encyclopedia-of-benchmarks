"""Direct ordered-factor assignment expansion, independent of Horner convolution."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MODULUS = 998_244_353
MAX_N = 4
MAX_COEFFICIENTS = 8
MAX_VALID_INPUT_LENGTH = 2 + MAX_COEFFICIENTS + (1 << MAX_N)
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _power_by_assignments(series: list[int], n: int, power: int) -> list[int]:
    result = [0] * (1 << n)
    factor_masks = [0] * power

    def assign(variable: int, union_mask: int) -> None:
        if variable == n:
            product = 1
            for mask in factor_masks:
                product = product * series[mask] % MODULUS
            result[union_mask] = (result[union_mask] + product) % MODULUS
            return
        bit = 1 << variable
        assign(variable + 1, union_mask)
        for factor in range(power):
            factor_masks[factor] |= bit
            assign(variable + 1, union_mask | bit)
            factor_masks[factor] ^= bit

    assign(0, 0)
    return result


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, list[int], list[int]] | None:
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return None
    count, n = values[0], values[1]
    if not 0 <= count <= MAX_COEFFICIENTS or not 0 <= n <= MAX_N:
        return None
    size = 1 << n
    if len(values) != 2 + count + size:
        return None
    polynomial = list(values[2:2 + count])
    series = list(values[2 + count:])
    if any(not 0 <= x < MODULUS for x in polynomial + series):
        return None
    return n, polynomial, series


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID, b""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID, b""
    n, polynomial, series = parsed
    byte_count = 8 * (1 << n)
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < byte_count)):
        return OUTPUT_ERROR, b""

    result = [0] * (1 << n)
    for power, coefficient in enumerate(polynomial):
        if coefficient == 0:
            continue
        expanded = _power_by_assignments(series, n, power)
        for mask, value in enumerate(expanded):
            result[mask] = (result[mask] + coefficient * value) % MODULUS
    return byte_count, b"".join(struct.pack("<q", x) for x in result)
