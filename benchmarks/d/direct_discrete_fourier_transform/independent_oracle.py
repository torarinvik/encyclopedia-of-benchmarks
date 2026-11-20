"""Independent polynomial-Horner reference for the same complex DFT."""
from __future__ import annotations

import math
from collections.abc import Sequence

MAX_N = 64
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_N
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = 2 * MAX_N
ABSOLUTE_TOLERANCE = 1e-9
RELATIVE_TOLERANCE = 1e-12


def expected_output(values: Sequence[int | float] | None,
                    output_capacity: int | None = None,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, list[float]]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, []
    if output_capacity is not None and (
            type(output_capacity) is not int or output_capacity < 0):
        return -1, []
    if input_length is not None and (
            type(input_length) is not int
            or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH):
        return -1, []
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, []
    if input_length is not None and input_length != len(values):
        return -1, []
    if not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return -1, []
    converted: list[float] = []
    for value in values:
        if type(value) not in (int, float):
            return -1, []
        try:
            number = float(value)
        except OverflowError:
            return -1, []
        if not math.isfinite(number):
            return -1, []
        converted.append(number)
    n_value = converted[0]
    if not n_value.is_integer():
        return -1, []
    n = int(n_value)
    if not 1 <= n <= MAX_N or len(values) != 1 + 2 * n:
        return -1, []
    coefficients = converted[1:]
    if any(value < -8.0 or value > 8.0 for value in coefficients):
        return -1, []
    if output_is_null or (output_capacity is not None and output_capacity < 2 * n):
        return -2, []

    result: list[float] = []
    tau = 2.0 * math.pi
    for frequency in range(n):
        angle = -tau * float(frequency) / float(n)
        root_real = math.cos(angle)
        root_imag = math.sin(angle)
        acc_real = 0.0
        acc_imag = 0.0
        for sample in range(n - 1, -1, -1):
            next_real = acc_real * root_real - acc_imag * root_imag
            next_imag = acc_real * root_imag + acc_imag * root_real
            coefficient_real = coefficients[2 * sample]
            coefficient_imag = coefficients[2 * sample + 1]
            acc_real = next_real + coefficient_real
            acc_imag = next_imag + coefficient_imag
        result.extend((acc_real, acc_imag))
    return 2 * n, result

