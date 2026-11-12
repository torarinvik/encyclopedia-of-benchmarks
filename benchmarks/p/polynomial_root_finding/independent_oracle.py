"""Direct finite-field evaluation oracle, independent of factor splitting."""

from __future__ import annotations

from collections.abc import Sequence
import struct

try:
    from .primary_oracle import (
        I64_MAX, I64_MIN, INVALID, MAX_INPUT_LENGTH, MAX_N, MODULUS, OUTPUT_ERROR,
    )
except ImportError:
    from primary_oracle import (
        I64_MAX, I64_MIN, INVALID, MAX_INPUT_LENGTH, MAX_N, MODULUS, OUTPUT_ERROR,
    )


def _poly_mod(left: list[int], right: list[int]) -> list[int]:
    left = [value % MODULUS for value in left]
    while len(left) > 1 and left[-1] == 0:
        left.pop()
    while len(right) > 1 and right[-1] == 0:
        right.pop()
    if len(right) == 1:
        return [0]
    inverse = pow(right[-1], MODULUS - 2, MODULUS)
    while len(left) >= len(right) and any(left):
        shift = len(left) - len(right)
        factor = left[-1] * inverse % MODULUS
        for index, value in enumerate(right):
            left[shift + index] = (left[shift + index] - factor * value) % MODULUS
        while len(left) > 1 and left[-1] == 0:
            left.pop()
    return left


def _poly_mul_mod(left: list[int], right: list[int], modulus_poly: list[int]) -> list[int]:
    product = [0] * (len(left) + len(right) - 1)
    for i, a in enumerate(left):
        for j, b in enumerate(right):
            product[i + j] = (product[i + j] + a * b) % MODULUS
    return _poly_mod(product, modulus_poly)


def _poly_pow_mod(base: list[int], exponent: int, modulus_poly: list[int]) -> list[int]:
    answer = [1]
    base = _poly_mod(base, modulus_poly)
    while exponent:
        if exponent & 1:
            answer = _poly_mul_mod(answer, base, modulus_poly)
        base = _poly_mul_mod(base, base, modulus_poly)
        exponent >>= 1
    return answer


def _poly_gcd(left: list[int], right: list[int]) -> list[int]:
    while right != [0]:
        left, right = right, _poly_mod(left, right)
    while len(left) > 1 and left[-1] == 0:
        left.pop()
    if left == [0]:
        return [0]
    inverse = pow(left[-1], MODULUS - 2, MODULUS)
    return [(value * inverse) % MODULUS for value in left]


def _linear_root_count(coefficients: list[int]) -> int:
    if len(coefficients) <= 1:
        return 0
    x_mod = _poly_mod([0, 1], coefficients)
    x_to_p = _poly_pow_mod(x_mod, MODULUS, coefficients)
    size = max(len(x_mod), len(x_to_p))
    difference = [0] * size
    for index in range(size):
        left = x_to_p[index] if index < len(x_to_p) else 0
        right = x_mod[index] if index < len(x_mod) else 0
        difference[index] = (left - right) % MODULUS
    while len(difference) > 1 and difference[-1] == 0:
        difference.pop()
    return len(_poly_gcd(coefficients.copy(), difference)) - 1


def _evaluate(coefficients: Sequence[int], point: int) -> int:
    result = 0
    for coefficient in reversed(coefficients):
        result = (result * point + coefficient) % MODULUS
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
    degree = values[0]
    if not 0 <= degree <= MAX_N or len(values) != degree + 2:
        return INVALID, b""
    coefficients = list(values[1:])
    if any(not 0 <= value < MODULUS for value in coefficients) or coefficients[-1] == 0:
        return INVALID, b""

    expected_roots = _linear_root_count(coefficients)
    roots: list[int] = []
    if expected_roots:
        for point in range(MODULUS):
            if _evaluate(coefficients, point) == 0:
                roots.append(point)
                if len(roots) == expected_roots:
                    break
    words = [len(roots), *roots]
    byte_count = 8 * len(words)
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < byte_count)):
        return OUTPUT_ERROR, b""
    return byte_count, b"".join(struct.pack("<q", value) for value in words)
