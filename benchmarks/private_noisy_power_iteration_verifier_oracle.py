"""Independent Newton-norm verifier for the fixed-point noisy power trace."""

from __future__ import annotations

import struct
from collections.abc import Sequence

S = 1_000_000
MAX_N = 4
MAX_L = 4
MAX_INPUT = 39


def _div_zero(numerator: int, denominator: int) -> int:
    return numerator // denominator if numerator >= 0 else -((-numerator) // denominator)


def _sqrt_floor_newton(number: int) -> int:
    if number == 0:
        return 0
    estimate = number
    next_estimate = (estimate + 1) // 2
    while next_estimate < estimate:
        estimate = next_estimate
        next_estimate = (estimate + number // estimate) // 2
    return estimate


def _decode(values: Sequence[int]) -> tuple[int, int, int, list[list[int]], list[int], list[list[int]]] | None:
    if len(values) < 11 or len(values) > MAX_INPUT or any(
            type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    n, count, sigma = values[0], values[1], values[2]
    if n not in (2, 3, 4) or count not in (1, 2, 3, 4) or not 0 <= sigma <= S:
        return None
    matrix_end = 3 + n*n
    vector_end = matrix_end + n
    if len(values) != vector_end + count*n:
        return None
    matrix = [list(values[3+i*n:3+(i+1)*n]) for i in range(n)]
    start = matrix_end
    initial = list(values[start:vector_end])
    noise = [list(values[vector_end+i*n:vector_end+(i+1)*n]) for i in range(count)]
    if any(abs(a) > S for row in matrix for a in row):
        return None
    for row in range(n):
        for col in range(row):
            if matrix[row][col] != matrix[col][row]:
                return None
    if any(abs(component) > S for component in initial) or sum(component**2 for component in initial) != S**2:
        return None
    if any(abs(component) > 2*S for row in noise for component in row):
        return None
    return n, count, sigma, matrix, initial, noise


def _run(decoded: tuple[int, int, int, list[list[int]], list[int], list[list[int]]]) -> list[int] | None:
    n, count, sigma, matrix, vector, noise_rows = decoded
    current = vector.copy()
    for noise in noise_rows:
        transformed = []
        for row in matrix:
            accumulator = 0
            for column in range(n):
                accumulator += row[column] * current[column]
            accumulator += sigma * noise[len(transformed)]
            transformed.append(_div_zero(accumulator, S))
        norm_sq = 0
        for component in transformed:
            norm_sq += component * component
        root = _sqrt_floor_newton(norm_sq)
        if root < 1:
            return None
        current = [_div_zero(component*S, root) for component in transformed]
    return current


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    decoded = _decode(values)
    if decoded is None:
        return -1, b""
    output = _run(decoded)
    if output is None:
        return -1, b""
    payload = b"".join(struct.pack("<q", item) for item in output)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
