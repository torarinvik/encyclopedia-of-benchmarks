"""Forward-difference/Newton evaluation for shifted polynomial samples."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MODULUS = 998_244_353
MAX_N = 16
MAX_M = 16
MAX_VALID_INPUT_LENGTH = 3 + MAX_N
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * MAX_M
MAX_WORKSPACE_BYTES = 4 * MAX_N * 8
INVALID = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _mod_pow(base: int, exponent: int) -> int:
    result = 1
    base %= MODULUS
    while exponent:
        if exponent & 1:
            result = result * base % MODULUS
        base = base * base % MODULUS
        exponent >>= 1
    return result


def _shift_samples(samples: list[int], start: int, count: int) -> list[int]:
    n = len(samples)
    differences = samples[:]
    factorial = [1] * n
    for k in range(1, n):
        factorial[k] = factorial[k - 1] * k % MODULUS
    inverse_factorial = [1] * n
    if n > 1:
        inverse_factorial[-1] = _mod_pow(factorial[-1], MODULUS - 2)
        for k in range(n - 1, 0, -1):
            inverse_factorial[k - 1] = inverse_factorial[k] * k % MODULUS

    newton = [0] * n
    for k in range(n):
        newton[k] = differences[0] * inverse_factorial[k] % MODULUS
        for i in range(n - k - 1):
            differences[i] = (differences[i + 1] - differences[i]) % MODULUS

    values: list[int] = []
    for offset in range(count):
        x = (start + offset) % MODULUS
        basis = 1
        total = 0
        for k, coefficient in enumerate(newton):
            total = (total + coefficient * basis) % MODULUS
            basis = basis * (x - k) % MODULUS
        values.append(total)
    return values


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
    if len(values) < 4 or len(values) > MAX_INPUT_LENGTH:
        return INVALID, b""
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return INVALID, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID, b""

    n, m, start = values[:3]
    if not 1 <= n <= MAX_N or not 1 <= m <= MAX_M or len(values) != 3 + n:
        return INVALID, b""
    if not 0 <= start < MODULUS or any(not 0 <= sample < MODULUS for sample in values[3:]):
        return INVALID, b""

    byte_count = 8 * m
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < byte_count)):
        return OUTPUT_ERROR, b""
    result = _shift_samples(list(values[3:]), start, m)
    return byte_count, b"".join(struct.pack("<q", value) for value in result)
