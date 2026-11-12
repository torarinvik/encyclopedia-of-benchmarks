"""Synthetic-division oracle for monomial-to-Newton basis conversion."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MODULUS = 998_244_353
MAX_N = 12
MAX_INPUT_LENGTH = 1 + 2 * MAX_N
MAX_OUTPUT_BYTES = 8 * MAX_N
INVALID = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _convert(coefficients: list[int], nodes: list[int]) -> list[int]:
    residual = coefficients[:]
    active = len(residual)
    answer: list[int] = []
    for node in nodes:
        value = 0
        for coefficient in reversed(residual[:active]):
            value = (value * node + coefficient) % MODULUS
        answer.append(value)
        if active == 1:
            continue
        quotient = [0] * (active - 1)
        quotient[-1] = residual[active - 1]
        for degree in range(active - 2, 0, -1):
            quotient[degree - 1] = (
                residual[degree] + node * quotient[degree]
            ) % MODULUS
        residual[:active - 1] = quotient
        active -= 1
    return answer


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
    if len(values) < 3 or len(values) > MAX_INPUT_LENGTH:
        return INVALID, b""
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return INVALID, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID, b""

    n = values[0]
    if type(n) is not int or not 1 <= n <= MAX_N or len(values) != 1 + 2 * n:
        return INVALID, b""
    coefficients = list(values[1 : n + 1])
    nodes = list(values[n + 1 :])
    if any(not 0 <= value < MODULUS for value in coefficients + nodes):
        return INVALID, b""

    byte_count = 8 * n
    if output_is_null or (
        output_capacity is not None
        and (type(output_capacity) is not int or output_capacity < byte_count)
    ):
        return OUTPUT_ERROR, b""
    converted = _convert(coefficients, nodes)
    return byte_count, b"".join(struct.pack("<q", value) for value in converted)
