"""Direct O(N^2) complex DFT reference for the bounded profile."""
from __future__ import annotations

import math
from collections.abc import Sequence

TAU = 2.0 * math.pi
MAX_N = 64
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_N
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = 2 * MAX_N
WORKSPACE_ELEMENTS = 0
ABSOLUTE_TOLERANCE = 1e-9
RELATIVE_TOLERANCE = 1e-12
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _decode(values: Sequence[int | float] | None, input_length: int | None,
            input_is_null: bool) -> tuple[int, list[float]] | None:
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    numbers: list[float] = []
    for value in values:
        if type(value) not in (int, float):
            return None
        try:
            number = float(value)
        except OverflowError:
            return None
        if not math.isfinite(number):
            return None
        numbers.append(number)
    n_value = numbers[0]
    if not n_value.is_integer():
        return None
    n = int(n_value)
    if not 1 <= n <= MAX_N or len(values) != 1 + 2 * n:
        return None
    if any(value < -8.0 or value > 8.0 for value in numbers[1:]):
        return None
    return n, numbers[1:]


def direct_dft(values: Sequence[int | float]) -> list[float]:
    """Evaluate each frequency bin by its defining nested sum."""
    n = int(float(values[0]))
    result = [0.0] * (2 * n)
    for frequency in range(n):
        real_sum = 0.0
        imag_sum = 0.0
        for sample in range(n):
            angle = -TAU * float(sample) * float(frequency) / float(n)
            cosine = math.cos(angle)
            sine = math.sin(angle)
            sample_real = float(values[1 + 2 * sample])
            sample_imag = float(values[2 + 2 * sample])
            real_sum += sample_real * cosine + sample_imag * sine
            imag_sum += sample_imag * cosine - sample_real * sine
        result[2 * frequency] = real_sum
        result[2 * frequency + 1] = imag_sum
    return result


def expected_output(values: Sequence[int | float] | None,
                    output_capacity: int | None = None,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, list[float]]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, []
    if output_capacity is not None and (
            type(output_capacity) is not int or output_capacity < 0):
        return INVALID_RESULT, []
    if input_length is not None and (
            type(input_length) is not int
            or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH):
        return INVALID_RESULT, []
    parsed = _decode(values, input_length, input_is_null)
    if parsed is None:
        return INVALID_RESULT, []
    n, _samples = parsed
    if output_is_null or (output_capacity is not None and output_capacity < 2 * n):
        return OUTPUT_ERROR, []
    return 2 * n, direct_dft(values)

