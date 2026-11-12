"""Brent–Kung baby-step/giant-step oracle for bounded FPS composition."""
from __future__ import annotations

from collections.abc import Sequence
import struct

MODULUS = 998_244_353
MAX_N = 32
MAX_INPUT_LENGTH = 65
MAX_PARSEABLE_INPUT_LENGTH = 66
MAX_OUTPUT_BYTES = 8 * MAX_N
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _invalid() -> tuple[int, bytes]:
    return INVALID_RESULT, b""


def _multiply(left: list[int], right: list[int], width: int) -> list[int]:
    product = [0] * width
    for i, left_value in enumerate(left[:width]):
        for j, right_value in enumerate(right[:width - i]):
            product[i + j] = (product[i + j] + left_value * right_value) % MODULUS
    return product


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or input_is_null or not isinstance(values, (list, tuple))
            or len(values) < 3 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))):
        return _invalid()
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return _invalid()

    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != 1 + 2 * n:
        return _invalid()
    outer = list(values[1:1 + n])
    inner = list(values[1 + n:])
    if (any(not 0 <= value < MODULUS for value in outer + inner)
            or inner[0] != 0):
        return _invalid()
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return _invalid()

    byte_count = 8 * n
    if output_is_null or (output_capacity is not None and output_capacity < byte_count):
        return OUTPUT_ERROR, b""

    block_size = 1
    while block_size * block_size < n:
        block_size += 1
    block_count = (n + block_size - 1) // block_size
    powers = [[0] * n for _ in range(block_size + 1)]
    powers[0][0] = 1
    for exponent in range(1, block_size + 1):
        powers[exponent] = _multiply(powers[exponent - 1], inner, n)

    blocks = [[0] * n for _ in range(block_count)]
    for block in range(block_count):
        start = block * block_size
        for offset in range(min(block_size, n - start)):
            coefficient = outer[start + offset]
            for degree in range(n):
                blocks[block][degree] = (
                    blocks[block][degree] + coefficient * powers[offset][degree]
                ) % MODULUS

    composed = blocks[-1]
    for block in range(block_count - 1, 0, -1):
        product = _multiply(composed, powers[block_size], n)
        composed = [
            (product[degree] + blocks[block - 1][degree]) % MODULUS
            for degree in range(n)
        ]
    encoded = b"".join(struct.pack("<q", coefficient) for coefficient in composed)
    return byte_count, encoded
