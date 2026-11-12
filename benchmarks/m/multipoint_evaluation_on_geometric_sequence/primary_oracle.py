"""Bluestein chirp-z evaluation with a bounded radix-2 NTT convolution."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MODULUS = 998_244_353
MAX_N = 8
MAX_M = 8
NTT_SIZE = 32
MAX_INPUT_LENGTH = 12
MAX_OUTPUT_BYTES = 64
MAX_WORKSPACE_BYTES = 1024
INVALID = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int, list[int]] | None:
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if not 5 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return None
    n, m, start, ratio = values[:4]
    if not 1 <= n <= MAX_N or not 1 <= m <= MAX_M or len(values) != 4 + n:
        return None
    if not 0 <= start < MODULUS or not 0 <= ratio < MODULUS:
        return None
    coefficients = list(values[4:])
    if any(not 0 <= coefficient < MODULUS for coefficient in coefficients):
        return None
    return m, start, [ratio, *coefficients]


def _mod_pow(base: int, exponent: int) -> int:
    result = 1
    while exponent:
        if exponent & 1:
            result = result * base % MODULUS
        base = base * base % MODULUS
        exponent >>= 1
    return result


def _ntt(values: list[int], inverse: bool) -> None:
    size = len(values)
    j = 0
    for i in range(1, size):
        bit = size >> 1
        while j & bit:
            j ^= bit
            bit >>= 1
        j ^= bit
        if i < j:
            values[i], values[j] = values[j], values[i]
    block = 2
    while block <= size:
        root = _mod_pow(3, (MODULUS - 1) // block)
        if inverse:
            root = _mod_pow(root, MODULUS - 2)
        half = block // 2
        for start in range(0, size, block):
            factor = 1
            for offset in range(half):
                even = values[start + offset]
                odd = values[start + offset + half] * factor % MODULUS
                values[start + offset] = (even + odd) % MODULUS
                values[start + offset + half] = (even - odd) % MODULUS
                factor = factor * root % MODULUS
        block *= 2
    if inverse:
        scale = _mod_pow(size, MODULUS - 2)
        for i in range(size):
            values[i] = values[i] * scale % MODULUS


def _evaluate(n: int, m: int, start: int, ratio: int, coefficients: list[int]) -> list[int]:
    if start == 0:
        return [coefficients[0]] * m
    if ratio == 0:
        at_start = 0
        for coefficient in reversed(coefficients):
            at_start = (at_start * start + coefficient) % MODULUS
        return [at_start, *([coefficients[0]] * (m - 1))]

    inverse_ratio = _mod_pow(ratio, MODULUS - 2)
    left = [0] * NTT_SIZE
    right = [0] * NTT_SIZE

    start_power = 1
    inverse_chirp = 1
    inverse_ratio_power = 1
    for degree, coefficient in enumerate(coefficients):
        left[n - 1 - degree] = coefficient * start_power % MODULUS * inverse_chirp % MODULUS
        start_power = start_power * start % MODULUS
        inverse_chirp = inverse_chirp * inverse_ratio_power % MODULUS
        inverse_ratio_power = inverse_ratio_power * inverse_ratio % MODULUS

    chirp = 1
    ratio_power = 1
    for index in range(n + m - 1):
        right[index] = chirp
        chirp = chirp * ratio_power % MODULUS
        ratio_power = ratio_power * ratio % MODULUS

    _ntt(left, False)
    _ntt(right, False)
    for i in range(NTT_SIZE):
        left[i] = left[i] * right[i] % MODULUS
    _ntt(left, True)

    result = [0] * m
    inverse_chirp = 1
    inverse_ratio_power = 1
    for index in range(m):
        result[index] = left[n - 1 + index] * inverse_chirp % MODULUS
        inverse_chirp = inverse_chirp * inverse_ratio_power % MODULUS
        inverse_ratio_power = inverse_ratio_power * inverse_ratio % MODULUS
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
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID, b""
    m, start, ratio_and_coefficients = parsed
    ratio = ratio_and_coefficients[0]
    coefficients = ratio_and_coefficients[1:]
    byte_count = 8 * m
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < byte_count)):
        return OUTPUT_ERROR, b""
    result = _evaluate(len(coefficients), m, start, ratio, coefficients)
    return byte_count, b"".join(struct.pack("<q", value) for value in result)
