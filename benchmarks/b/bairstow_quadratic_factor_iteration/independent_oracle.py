"""Direct-convolution reference for the DLMF Bairstow update trace."""

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
WORKSPACE_BYTES = 1024
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2


def _read(values: Sequence[int] | None, input_is_null: bool,
          input_length: int | None) -> tuple[int, list[int], int, int, int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
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
    if any(value < 0 or value >= MODULUS for value in (*coefficients, start_s, start_t)):
        return None
    if coefficients[degree] == 0 or not MIN_ITERATIONS <= iterations <= MAX_ITERATIONS:
        return None
    return degree, coefficients, start_s, start_t, iterations


def convolution_update(degree: int, coefficients: Sequence[int],
                       s_value: int, t_value: int) -> tuple[int, int] | None:
    """Evaluate the two synthetic sequences as convolution sums, not recurrences."""
    reciprocal = [1] + [0] * degree
    if degree >= 1:
        reciprocal[1] = s_value
    for order in range(2, degree + 1):
        reciprocal[order] = (s_value * reciprocal[order - 1]
                             + t_value * reciprocal[order - 2]) % MODULUS

    q = [0] * (degree + 2)
    for index in range(degree + 1):
        q[index] = sum(coefficients[source] * reciprocal[source - index]
                       for source in range(index, degree + 1)) % MODULUS
    r = [0] * (degree + 2)
    for index in range(degree + 1):
        r[index] = sum(q[source] * reciprocal[source - index]
                       for source in range(index, degree + 1)) % MODULUS

    ell = (s_value * r[2] + t_value * r[3]) % MODULUS
    denominator = (r[2] * r[2] - ell * r[3]) % MODULUS
    if denominator == 0:
        return None
    inverse = pow(denominator, MODULUS - 2, MODULUS)
    delta_s = ((r[3] * q[0] - r[2] * q[1]) % MODULUS) * inverse % MODULUS
    delta_t = ((ell * q[1] - r[2] * q[0]) % MODULUS) * inverse % MODULUS
    return (s_value + delta_s) % MODULUS, (t_value + delta_t) % MODULUS


def independent_trace(degree: int, coefficients: Sequence[int], s_value: int,
                      t_value: int, iterations: int) -> list[tuple[int, int]] | None:
    trace = [(s_value, t_value)]
    for _ in range(iterations):
        pair = convolution_update(degree, coefficients, s_value, t_value)
        if pair is None:
            return None
        s_value, t_value = pair
        trace.append(pair)
    return trace


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _read(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    degree, coefficients, s_value, t_value, iterations = parsed
    trace = independent_trace(degree, coefficients, s_value, t_value, iterations)
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
