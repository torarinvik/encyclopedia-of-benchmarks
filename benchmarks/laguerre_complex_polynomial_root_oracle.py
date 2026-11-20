"""Primary oracle for the bounded complex Laguerre root iteration."""

from __future__ import annotations

import math
from collections.abc import Sequence

INVALID_RESULT = -1
OUTPUT_ERROR = -2
NUMERICAL_FAILURE = -3
MIN_DEGREE = 2
MAX_DEGREE = 6
MIN_COEFFICIENT = -16
MAX_COEFFICIENT = 16
MIN_SEED_MILLI = -4000
MAX_SEED_MILLI = 4000
MIN_TOLERANCE_MICRO = 1
MAX_TOLERANCE_MICRO = 1000
MIN_ITERATIONS = 8
MAX_ITERATIONS = 128
MAX_VALID_INPUT_LENGTH = MAX_DEGREE + 6
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = 2
ABSOLUTE_TOLERANCE = 2.0e-6
RELATIVE_TOLERANCE = 1.0e-8


def _integer(value: object, low: int, high: int) -> int | None:
    if type(value) not in (int, float):
        return None
    try:
        number = float(value)
    except OverflowError:
        return None
    if not math.isfinite(number) or number != math.trunc(number):
        return None
    if not low <= number <= high:
        return None
    return int(number)


def _decode(values: Sequence[int | float] | None, input_is_null: bool,
            input_length: int | None) -> tuple[int, list[float], complex, float, int] | None:
    if (not isinstance(values, (list, tuple)) or type(input_is_null) is not bool
            or input_is_null or len(values) > MAX_PARSEABLE_INPUT_LENGTH):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return None
    if not 1 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    degree = _integer(values[0], MIN_DEGREE, MAX_DEGREE)
    if degree is None or input_length != degree + 6:
        return None
    coefficients: list[float] = []
    for value in values[1:degree + 2]:
        coefficient = _integer(value, MIN_COEFFICIENT, MAX_COEFFICIENT)
        if coefficient is None:
            return None
        coefficients.append(float(coefficient))
    if coefficients[-1] == 0.0:
        return None
    real_milli = _integer(values[degree + 2], MIN_SEED_MILLI, MAX_SEED_MILLI)
    imag_milli = _integer(values[degree + 3], MIN_SEED_MILLI, MAX_SEED_MILLI)
    tolerance_micro = _integer(values[degree + 4], MIN_TOLERANCE_MICRO, MAX_TOLERANCE_MICRO)
    iterations = _integer(values[degree + 5], MIN_ITERATIONS, MAX_ITERATIONS)
    if None in (real_milli, imag_milli, tolerance_micro, iterations):
        return None
    start = complex(real_milli / 1000.0, imag_milli / 1000.0)
    return degree, coefficients, start, tolerance_micro / 1_000_000.0, iterations


def _finite_complex(value: complex) -> bool:
    return math.isfinite(value.real) and math.isfinite(value.imag)


def _horner(coefficients: list[float], z: complex) -> tuple[complex, complex, complex, float]:
    """Evaluate P, P', P'' together in descending Horner order."""
    degree = len(coefficients) - 1
    p = complex(coefficients[degree], 0.0)
    first = 0j
    second = 0j
    for index in range(degree - 1, -1, -1):
        second = second * z + 2.0 * first
        first = first * z + p
        p = p * z + coefficients[index]
    scale = abs(coefficients[degree])
    radius = abs(z)
    for index in range(degree - 1, -1, -1):
        scale = scale * radius + abs(coefficients[index])
    return p, first, second, scale


def _sqrt_complex(value: complex) -> complex:
    """Principal square root with the nonnegative imaginary tie at y=0."""
    radius = abs(value)
    real = math.sqrt(max(0.0, (radius + value.real) * 0.5))
    imag_magnitude = math.sqrt(max(0.0, (radius - value.real) * 0.5))
    imag = -imag_magnitude if value.imag < 0.0 else imag_magnitude
    return complex(real, imag)


def _solve(parsed: tuple[int, list[float], complex, float, int]) -> tuple[int, tuple[float, float]]:
    degree, coefficients, z, tolerance, iterations = parsed
    for step in range(iterations + 1):
        if not _finite_complex(z):
            return NUMERICAL_FAILURE, ()
        p, first, second, scale = _horner(coefficients, z)
        if (not _finite_complex(p) or not _finite_complex(first)
                or not _finite_complex(second) or not math.isfinite(scale)):
            return NUMERICAL_FAILURE, ()
        if abs(p) <= tolerance * max(1.0, scale):
            return 2, (z.real, z.imag)
        if step == iterations or p == 0j:
            return NUMERICAL_FAILURE, ()

        try:
            g = first / p
            h = g * g - second / p
        except (OverflowError, ZeroDivisionError):
            return NUMERICAL_FAILURE, ()
        radicand = (degree - 1) * (degree * h - g * g)
        if not (_finite_complex(g) and _finite_complex(h) and _finite_complex(radicand)):
            return NUMERICAL_FAILURE, ()
        root = _sqrt_complex(radicand)
        plus = g + root
        minus = g - root
        denominator = plus if abs(plus) >= abs(minus) else minus
        denominator_magnitude = abs(denominator)
        if denominator_magnitude == 0.0 or not math.isfinite(denominator_magnitude):
            return NUMERICAL_FAILURE, ()
        correction = degree / denominator
        if not _finite_complex(correction):
            return NUMERICAL_FAILURE, ()
        z -= correction
    return NUMERICAL_FAILURE, ()


def expected_output(values: Sequence[int | float] | None,
                    output_capacity: int | None = None,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, tuple[float, ...]]:
    """Return ``(status, [real,imag])`` for one supplied-seed Laguerre solve."""
    parsed = _decode(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, ()
    if type(output_is_null) is not bool:
        return OUTPUT_ERROR, ()
    capacity = MAX_OUTPUT_ELEMENTS if output_capacity is None else output_capacity
    if type(capacity) is not int or capacity < 0 or output_is_null or capacity < MAX_OUTPUT_ELEMENTS:
        return OUTPUT_ERROR, ()
    return _solve(parsed)


def expected_result(values: Sequence[int | float] | None, **kwargs: object) -> int:
    """Return only the exported ABI status."""
    return expected_output(values, **kwargs)[0]


def certificate_holds(values: Sequence[int | float] | None,
                      candidate: Sequence[float]) -> bool:
    """Check a candidate root using the polynomial's scaled residual."""
    parsed = _decode(values, False, None)
    if parsed is None or not isinstance(candidate, (list, tuple)) or len(candidate) != 2:
        return False
    if any(type(value) not in (int, float) for value in candidate):
        return False
    try:
        candidate_values = (float(candidate[0]), float(candidate[1]))
    except OverflowError:
        return False
    if not all(math.isfinite(value) for value in candidate_values):
        return False
    _, coefficients, _, tolerance, _ = parsed
    z = complex(*candidate_values)
    p, _, _, scale = _horner(coefficients, z)
    return (math.isfinite(scale) and _finite_complex(p)
            and abs(p) <= tolerance * max(1.0, scale))
