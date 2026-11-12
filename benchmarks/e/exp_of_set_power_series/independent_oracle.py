"""Partition-enumeration oracle for the square-zero set-series exponential."""

from __future__ import annotations

from collections.abc import Sequence
import struct

try:
    from .primary_oracle import (
        I64_MAX, I64_MIN, INVALID, MAX_INPUT_LENGTH, MAX_N, MODULUS, OUTPUT_ERROR,
    )
except ImportError:  # Direct invocation from this package directory.
    from primary_oracle import (
        I64_MAX, I64_MIN, INVALID, MAX_INPUT_LENGTH, MAX_N, MODULUS, OUTPUT_ERROR,
    )


def _partitions(mask: int, coefficients: list[int]):
    if mask == 0:
        yield 1, 0
        return
    first = mask & -mask
    remaining = mask ^ first
    block_rest = remaining
    while True:
        block = first | block_rest
        for product, count in _partitions(mask ^ block, coefficients):
            yield product * coefficients[block] % MODULUS, count + 1
        if block_rest == 0:
            break
        block_rest = (block_rest - 1) & remaining


def _partition_exponential(coefficients: list[int], n: int) -> list[int]:
    result = [0] * (1 << n)
    for mask in range(1 << n):
        total = 0
        for product, _count in _partitions(mask, coefficients):
            total = (total + product) % MODULUS
        result[mask] = total
    return result


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
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return INVALID, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID, b""
    n = values[0]
    if not 0 <= n <= MAX_N:
        return INVALID, b""
    size = 1 << n
    if len(values) != 1 + size:
        return INVALID, b""
    coefficients = list(values[1:])
    if coefficients[0] != 0 or any(not 0 <= value < MODULUS for value in coefficients):
        return INVALID, b""

    byte_count = size * 8
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < byte_count)):
        return OUTPUT_ERROR, b""
    result = _partition_exponential(coefficients, n)
    return byte_count, b"".join(struct.pack("<q", value) for value in result)
