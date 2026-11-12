"""Iterative subset-convolution oracle for weighted set-series powers."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MODULUS = 998_244_353
MAX_N = 4
MAX_M = 8
MAX_SIZE = 1 << MAX_N
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_SIZE
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * MAX_M
MAX_WORKSPACE_BYTES = 512
INVALID = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _multiply(left: list[int], right: list[int], size: int) -> list[int]:
    product = [0] * size
    for mask in range(size):
        subset = mask
        while True:
            product[mask] = (
                product[mask] + left[subset] * right[mask ^ subset]
            ) % MODULUS
            if subset == 0:
                break
            subset = (subset - 1) & mask
    return product


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

    current = [0] * size
    current[0] = 1
    answers: list[int] = []
    for power in range(powers):
        projection = 0
        for mask in range(size):
            projection = (projection + weights[mask] * current[mask]) % MODULUS
        answers.append(projection)
        if power + 1 < powers:
            current = _multiply(current, series, size)
    return byte_count, b"".join(struct.pack("<q", answer) for answer in answers)
