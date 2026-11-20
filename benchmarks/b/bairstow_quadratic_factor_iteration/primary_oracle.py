"""DLMF q/r recurrence and quadratic-factor updates over a finite field."""

from __future__ import annotations

import struct
from collections.abc import Sequence

ALGORITHM = "bairstow_quadratic_factor_iteration"
MODULUS = 998244353
MIN_DEGREE = 3
MAX_DEGREE = 8
MIN_ITERATIONS = 1
MAX_ITERATIONS = 4
MAX_VALID_INPUT_LENGTH = MAX_DEGREE + 5
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (2 * MAX_ITERATIONS + 3)
WORKSPACE_BYTES = 512
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, list[int], int, int, int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return None
    degree = values[0]
    if not MIN_DEGREE <= degree <= MAX_DEGREE or input_length != degree + 5:
        return None
    coefficients = list(values[1:degree + 2])
    start_s, start_t, iterations = values[degree + 2:degree + 5]
    if any(not 0 <= value < MODULUS for value in (*coefficients, start_s, start_t)):
        return None
    if coefficients[degree] == 0 or not MIN_ITERATIONS <= iterations <= MAX_ITERATIONS:
        return None
    return degree, coefficients, start_s, start_t, iterations


def bairstow_step(degree: int, coefficients: Sequence[int], s_value: int,
                  t_value: int) -> tuple[int, int] | None:
    """Apply one DLMF Bairstow q/r back sweep and correction."""
    q = [0] * (degree + 2)
    r = [0] * (degree + 2)
    q[degree] = coefficients[degree]
    r[degree] = coefficients[degree]
    for index in range(degree - 1, -1, -1):
        q[index] = (coefficients[index] + s_value * q[index + 1]
                    + t_value * q[index + 2]) % MODULUS
        r[index] = (q[index] + s_value * r[index + 1]
                    + t_value * r[index + 2]) % MODULUS

    r2, r3 = r[2], r[3]
    q0, q1 = q[0], q[1]
    ell = (s_value * r2 + t_value * r3) % MODULUS
    denominator = (r2 * r2 - ell * r3) % MODULUS
    if denominator == 0:
        return None
    inverse = pow(denominator, MODULUS - 2, MODULUS)
    delta_s = (r3 * q0 - r2 * q1) % MODULUS * inverse % MODULUS
    delta_t = (ell * q1 - r2 * q0) % MODULUS * inverse % MODULUS
    return (s_value + delta_s) % MODULUS, (t_value + delta_t) % MODULUS


def bairstow_trace(degree: int, coefficients: Sequence[int], s_value: int,
                   t_value: int, iterations: int) -> list[tuple[int, int]] | None:
    trace = [(s_value, t_value)]
    for _ in range(iterations):
        next_pair = bairstow_step(degree, coefficients, s_value, t_value)
        if next_pair is None:
            return None
        s_value, t_value = next_pair
        trace.append(next_pair)
    return trace


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    degree, coefficients, s_value, t_value, iterations = parsed
    trace = bairstow_trace(degree, coefficients, s_value, t_value, iterations)
    if trace is None:
        return INVALID_RESULT, b""
    required = 8 * (1 + 2 * len(trace))
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or output_is_null
            or type(effective_capacity) is not int or effective_capacity < 0
            or effective_capacity < required):
        return OUTPUT_ERROR_RESULT, b""
    words = [len(trace), *(component for pair in trace for component in pair)]
    return required, struct.pack("<" + "q" * len(words), *words)
