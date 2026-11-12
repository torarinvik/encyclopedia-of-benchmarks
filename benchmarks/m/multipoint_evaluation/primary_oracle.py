"""Product/remainder-tree oracle for bounded multipoint evaluation."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MODULUS = 998_244_353
MAX_N = 8
MAX_M = 8
MAX_INPUT_LENGTH = 18
MAX_OUTPUT_BYTES = 64
MAX_WORKSPACE_BYTES = 4096
INVALID = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[list[int], list[int]] | None:
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if not 4 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return None
    n, m = values[0], values[1]
    if not 1 <= n <= MAX_N or not 1 <= m <= MAX_M or len(values) != 2 + n + m:
        return None
    coefficients = list(values[2:2 + n])
    points = list(values[2 + n:])
    if any(not 0 <= value < MODULUS for value in coefficients + points):
        return None
    if coefficients[-1] == 0:
        return None
    return coefficients, points


def _multiply(left: list[int], right: list[int]) -> list[int]:
    result = [0] * (len(left) + len(right) - 1)
    for i, a in enumerate(left):
        for j, b in enumerate(right):
            result[i + j] = (result[i + j] + a * b) % MODULUS
    return result


def _remainder(dividend: list[int], divisor: list[int]) -> list[int]:
    if len(divisor) == 1 and divisor[0] == 1:
        return [0]
    result = dividend[:]
    while len(result) > 1 and result[-1] == 0:
        result.pop()
    if len(result) < len(divisor):
        return result
    while len(result) >= len(divisor):
        shift = len(result) - len(divisor)
        factor = result[-1]
        for degree, coefficient in enumerate(divisor):
            slot = shift + degree
            result[slot] = (result[slot] - factor * coefficient) % MODULUS
        while len(result) > 1 and result[-1] == 0:
            result.pop()
    return result


def _evaluate_tree(coefficients: list[int], points: list[int]) -> list[int]:
    leaf_base = 1
    while leaf_base < len(points):
        leaf_base *= 2
    products = [[1] for _ in range(2 * leaf_base)]
    for index, point in enumerate(points):
        products[leaf_base + index] = [(-point) % MODULUS, 1]
    for node in range(leaf_base - 1, 0, -1):
        products[node] = _multiply(products[2 * node], products[2 * node + 1])

    remainders: list[list[int] | None] = [None] * (2 * leaf_base)
    remainders[1] = _remainder(coefficients, products[1])
    for node in range(1, leaf_base):
        parent_remainder = remainders[node]
        if parent_remainder is None:
            continue
        for child in (2 * node, 2 * node + 1):
            if products[child] != [1]:
                remainders[child] = _remainder(parent_remainder, products[child])
    return [remainders[leaf_base + index][0] for index in range(len(points))]  # type: ignore[index]


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
    coefficients, points = parsed
    byte_count = 8 * len(points)
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < byte_count)):
        return OUTPUT_ERROR, b""
    results = _evaluate_tree(coefficients, points)
    return byte_count, b"".join(struct.pack("<q", value) for value in results)
