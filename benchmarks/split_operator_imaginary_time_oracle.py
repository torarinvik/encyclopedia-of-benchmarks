"""Direct-DFT oracle for a bounded imaginary-time split-operator step."""

from collections.abc import Sequence
import math

MAX_N = 64
MAX_STEPS = 8
MAX_INPUT_LENGTH = 2 + 4 * MAX_N
MAX_OUTPUT_ELEMENTS = 2 * MAX_N
WORKSPACE_ELEMENTS = 2 * MAX_N
ABSOLUTE_TOLERANCE = 1e-10
RELATIVE_TOLERANCE = 1e-10


def _is_int_float(value: object, minimum: int, maximum: int) -> bool:
    return (type(value) in (int, float) and math.isfinite(float(value))
            and float(value).is_integer() and minimum <= int(value) <= maximum)


def _direct_transform(real: list[float], imag: list[float], inverse: bool
                      ) -> tuple[list[float], list[float]]:
    """Compute one DFT directly; deliberately independent of the ports' FFT."""
    n = len(real)
    sign = 1.0 if inverse else -1.0
    transformed_real = [0.0] * n
    transformed_imag = [0.0] * n
    for frequency in range(n):
        for position in range(n):
            angle = sign * 2.0 * math.pi * frequency * position / n
            cosine = math.cos(angle)
            sine = math.sin(angle)
            transformed_real[frequency] += real[position] * cosine - imag[position] * sine
            transformed_imag[frequency] += real[position] * sine + imag[position] * cosine
    if inverse:
        transformed_real = [value / n for value in transformed_real]
        transformed_imag = [value / n for value in transformed_imag]
    return transformed_real, transformed_imag


def expected_output(values: Sequence[int | float] | None,
                    output_capacity: int | None = None,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, list[float]]:
    """Return ``(result, interleaved_complex_values)`` for the float64 ABI."""
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or (output_capacity is not None
                and (type(output_capacity) is not int or output_capacity < 0))
            or (input_length is not None
                and (type(input_length) is not int
                     or not 0 <= input_length <= MAX_INPUT_LENGTH))):
        return -1, []
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, []
    if (len(values) < 2 or len(values) > MAX_INPUT_LENGTH
            or (input_length is not None and input_length != len(values))
            or any(type(value) not in (int, float) or not math.isfinite(float(value))
                   for value in values)):
        return -1, []
    n_value, steps_value = values[:2]
    if (not _is_int_float(n_value, 2, MAX_N)
            or not _is_int_float(steps_value, 0, MAX_STEPS)):
        return -1, []
    n = int(n_value)
    steps = int(steps_value)
    if n & (n - 1) or len(values) != 2 + 4 * n:
        return -1, []

    position_start = 2
    momentum_start = position_start + n
    state_start = momentum_start + n
    position_factors = [float(value) for value in values[position_start:momentum_start]]
    momentum_factors = [float(value) for value in values[momentum_start:state_start]]
    state_values = [float(value) for value in values[state_start:]]
    if (any(not 0.25 <= value <= 1.0 for value in position_factors)
            or any(not 0.25 <= value <= 1.0 for value in momentum_factors)
            or any(abs(value) > 1.0 for value in state_values)):
        return -1, []
    real = state_values[0::2]
    imag = state_values[1::2]
    norm = math.sqrt(sum(re * re + im * im for re, im in zip(real, imag)))
    if not norm > 0.0:
        return -1, []

    def normalize() -> None:
        nonlocal real, imag
        length = math.sqrt(sum(re * re + im * im for re, im in zip(real, imag)))
        real = [value / length for value in real]
        imag = [value / length for value in imag]

    normalize()
    for _ in range(steps):
        real = [value * factor for value, factor in zip(real, position_factors)]
        imag = [value * factor for value, factor in zip(imag, position_factors)]
        real, imag = _direct_transform(real, imag, inverse=False)
        real = [value * factor for value, factor in zip(real, momentum_factors)]
        imag = [value * factor for value, factor in zip(imag, momentum_factors)]
        real, imag = _direct_transform(real, imag, inverse=True)
        real = [value * factor for value, factor in zip(real, position_factors)]
        imag = [value * factor for value, factor in zip(imag, position_factors)]
        normalize()

    output = [component for pair in zip(real, imag) for component in pair]
    if output_is_null or output_capacity is not None and output_capacity < len(output):
        return -2, []
    return len(output), output
