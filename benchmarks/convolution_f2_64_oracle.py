"""Primary bounded schoolbook convolution oracle over GF(2^64)."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 8
MAX_M = 8
MAX_VALID_INPUT_LENGTH = 2 + MAX_N + MAX_M
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (MAX_N + MAX_M - 1)
FIELD_REDUCTION = 0x1B
U64_MASK = (1 << 64) - 1


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool) -> tuple[list[int], list[int]] | None:
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 2
            or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values)):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    n, m = values[0], values[1]
    if not 1 <= n <= MAX_N or not 1 <= m <= MAX_M:
        return None
    if input_length != 2 + n + m:
        return None
    return ([value & U64_MASK for value in values[2:2 + n]],
            [value & U64_MASK for value in values[2 + n:]])


def _multiply(left: int, right: int) -> int:
    """Multiply by scanning the multiplier and reducing after each x shift."""
    product = 0
    shifted = left
    multiplier = right
    for _ in range(64):
        if multiplier & 1:
            product ^= shifted
        carry = shifted >> 63
        shifted = (shifted << 1) & U64_MASK
        if carry:
            shifted ^= FIELD_REDUCTION
        multiplier >>= 1
    return product


def _convolve(left: list[int], right: list[int]) -> list[int]:
    output = [0] * (len(left) + len(right) - 1)
    for i, a_value in enumerate(left):
        for j, b_value in enumerate(right):
            output[i + j] ^= _multiply(a_value, b_value)
    return output


def expected_output(values: Sequence[int] | None,
                    output_capacity: int | None = None,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return -1, b""
    left, right = parsed
    needed = 8 * (len(left) + len(right) - 1)
    if type(output_is_null) is not bool:
        return -2, b""
    if output_capacity is None:
        output_capacity = MAX_OUTPUT_BYTES
    if type(output_capacity) is not int or output_capacity < 0:
        return -2, b""
    if output_is_null or output_capacity < needed:
        return -2, b""
    encoded = bytearray()
    for coefficient in _convolve(left, right):
        encoded.extend(coefficient.to_bytes(8, "little"))
    return needed, bytes(encoded)
