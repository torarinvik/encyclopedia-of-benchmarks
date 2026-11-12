"""Oracle for a bounded deterministic replay of PARSEC's HJM path kernel."""

from __future__ import annotations

from collections.abc import Sequence
import math

INVALID_RESULT = -1
OUTPUT_ERROR = -2
MIN_STEPS = 2
MAX_STEPS = 8
MIN_FACTORS = 1
MAX_FACTORS = 3
YEARS_VALUES = (1.0, 2.0, 3.0)
MAX_INPUT_LENGTH = 54
MAX_OUTPUT_LENGTH = MAX_STEPS * MAX_STEPS
ABSOLUTE_TOLERANCE = 1e-12
RELATIVE_TOLERANCE = 1e-12


def _finite_number(value: object) -> bool:
    if type(value) not in (int, float):
        return False
    try:
        return math.isfinite(float(value))
    except OverflowError:
        return False


def _validated(values: Sequence[int | float] | None, input_length: int | None,
               input_is_null: bool) -> tuple[int, int, float, list[float], list[list[float]], list[list[float]]] | None:
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    length = len(values) if input_length is None else input_length
    if (type(length) is not int or length != len(values)
            or not 7 <= length <= MAX_INPUT_LENGTH):
        return None
    if not all(_finite_number(value) for value in values):
        return None

    steps_value, factors_value = float(values[0]), float(values[1])
    if (steps_value != math.trunc(steps_value)
            or factors_value != math.trunc(factors_value)):
        return None
    steps, factors = int(steps_value), int(factors_value)
    if not MIN_STEPS <= steps <= MAX_STEPS or not MIN_FACTORS <= factors <= MAX_FACTORS:
        return None
    expected_length = 3 + steps + 2 * factors * (steps - 1)
    if length != expected_length:
        return None

    years = float(values[2])
    if years not in YEARS_VALUES:
        return None
    yield_start = 3
    yields = [float(value) for value in values[yield_start:yield_start + steps]]
    if any(not -0.05 <= value <= 0.20 for value in yields):
        return None

    vol_start = yield_start + steps
    vol_count = factors * (steps - 1)
    flat_vols = [float(value) for value in values[vol_start:vol_start + vol_count]]
    if any(not 0.0 <= value <= 0.30 for value in flat_vols):
        return None
    vols = [flat_vols[factor * (steps - 1):(factor + 1) * (steps - 1)]
            for factor in range(factors)]

    shock_start = vol_start + vol_count
    flat_shocks = [float(value) for value in values[shock_start:]]
    if any(not -3.0 <= value <= 3.0 for value in flat_shocks):
        return None
    shocks = [flat_shocks[time * factors:(time + 1) * factors]
              for time in range(steps - 1)]
    return steps, factors, years, yields, vols, shocks


def _path(steps: int, factors: int, years: float, yields: list[float],
          vols: list[list[float]], shocks: list[list[float]],
          independent_drift: bool) -> list[float]:
    dt = years / steps
    forward = [0.0] * steps
    forward[0] = yields[0]
    for maturity in range(1, steps):
        forward[maturity] = ((maturity + 1) * yields[maturity]
                             - maturity * yields[maturity - 1])

    factor_drifts = [[0.0] * (steps - 1) for _ in range(factors)]
    if independent_drift:
        for factor in range(factors):
            prefix = 0.0
            previous_prefix_square = 0.0
            for maturity in range(steps - 1):
                prefix += vols[factor][maturity]
                prefix_square = prefix * prefix
                factor_drifts[factor][maturity] = (
                    0.5 * dt * (prefix_square - previous_prefix_square))
                previous_prefix_square = prefix_square
    else:
        for factor in range(factors):
            factor_drifts[factor][0] = (
                0.5 * dt * vols[factor][0] * vols[factor][0])
            for maturity in range(1, steps - 1):
                drift = 0.0
                for prior in range(maturity):
                    drift -= factor_drifts[factor][prior]
                prefix_vol = 0.0
                for prior in range(maturity + 1):
                    prefix_vol += vols[factor][prior]
                drift += 0.5 * dt * prefix_vol * prefix_vol
                factor_drifts[factor][maturity] = drift

    total_drift = [0.0] * (steps - 1)
    for maturity in range(steps - 1):
        for factor in range(factors):
            total_drift[maturity] += factor_drifts[factor][maturity]

    matrix = [[0.0] * steps for _ in range(steps)]
    matrix[0] = forward
    root_dt = math.sqrt(dt)
    for time in range(1, steps):
        for maturity in range(steps - time):
            total_shock = 0.0
            for factor in range(factors):
                total_shock += vols[factor][maturity] * shocks[time - 1][factor]
            matrix[time][maturity] = (
                matrix[time - 1][maturity + 1]
                + total_drift[maturity] * dt
                + root_dt * total_shock
            )
    return [value for row in matrix for value in row]


def expected_output(values: Sequence[int | float] | None,
                    output_capacity: int | None = None,
                    output_is_null: bool = False,
                    input_length: int | None = None,
                    input_is_null: bool = False) -> tuple[int, list[float]]:
    """Return the output element count and flattened path, or the ABI error code."""
    parsed = _validated(values, input_length, input_is_null)
    if parsed is None:
        return INVALID_RESULT, []
    steps, factors, years, yields, vols, shocks = parsed
    result = _path(steps, factors, years, yields, vols, shocks, False)
    needed = steps * steps
    if output_is_null or (output_capacity is not None and output_capacity < needed):
        return OUTPUT_ERROR, []
    return needed, result


def independent_output(values: Sequence[int | float] | None,
                       output_capacity: int | None = None,
                       output_is_null: bool = False,
                       input_length: int | None = None,
                       input_is_null: bool = False) -> tuple[int, list[float]]:
    """Independent oracle using the closed prefix-square form of HJM drift."""
    parsed = _validated(values, input_length, input_is_null)
    if parsed is None:
        return INVALID_RESULT, []
    steps, factors, years, yields, vols, shocks = parsed
    result = _path(steps, factors, years, yields, vols, shocks, True)
    needed = steps * steps
    if output_is_null or (output_capacity is not None and output_capacity < needed):
        return OUTPUT_ERROR, []
    return needed, result
