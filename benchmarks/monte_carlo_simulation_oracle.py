"""Oracle for the deterministic R Monte Carlo option-price contract."""

from __future__ import annotations

import math
from collections.abc import Sequence

MIN_S0 = 1.0
MAX_S0 = 1_000.0
MIN_STRIKE = 0.0
MAX_STRIKE = 2_000.0
MIN_RATE = -0.25
MAX_RATE = 0.25
MIN_VOLATILITY = 0.0
MAX_VOLATILITY = 0.5
MATURITIES = (0.25, 0.5, 1.0, 2.0)
STEP_COUNTS = (1, 2, 4, 8, 16)
MIN_SIMULATIONS = 1
MAX_SIMULATIONS = 32
MIN_NORMAL = -3.0
MAX_NORMAL = 3.0
MAX_VALID_INPUT_LENGTH = 7 + max(STEP_COUNTS) * MAX_SIMULATIONS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2
ABSOLUTE_TOLERANCE = 1e-12
RELATIVE_TOLERANCE = 1e-12


def _finite_number(value: object) -> bool:
    if type(value) not in (int, float):
        return False
    try:
        return math.isfinite(float(value))
    except (OverflowError, ValueError):
        return False


def _parse(values: Sequence[int | float] | None) -> tuple[float, float, float, float, float, int, int, list[float]] | None:
    if (
        not isinstance(values, (list, tuple))
        or not 7 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(not _finite_number(value) for value in values)
    ):
        return None

    raw = [float(value) for value in values]
    s0, strike, rate, volatility, maturity, step_value, simulation_value = raw[:7]
    if not (MIN_S0 <= s0 <= MAX_S0 and MIN_STRIKE <= strike <= MAX_STRIKE):
        return None
    if not MIN_RATE <= rate <= MAX_RATE:
        return None
    if not MIN_VOLATILITY <= volatility <= MAX_VOLATILITY:
        return None
    if maturity not in MATURITIES:
        return None
    if not step_value.is_integer() or not simulation_value.is_integer():
        return None

    steps = int(step_value)
    simulations = int(simulation_value)
    if steps not in STEP_COUNTS or not MIN_SIMULATIONS <= simulations <= MAX_SIMULATIONS:
        return None
    if len(raw) != 7 + steps * simulations:
        return None

    normals = raw[7:]
    if any(not MIN_NORMAL <= normal <= MAX_NORMAL for normal in normals):
        return None
    return s0, strike, rate, volatility, maturity, steps, simulations, normals


def expected_result(values: Sequence[int | float] | None) -> float | None:
    """Return the discounted call price, or None for an invalid input frame."""
    parsed = _parse(values)
    if parsed is None:
        return None
    s0, strike, rate, volatility, maturity, steps, simulations, normals = parsed

    dt = maturity / steps
    sqrt_dt = math.sqrt(dt)
    drift = (rate - 0.5 * volatility**2) * maturity
    payoffs: list[float] = []
    for simulation in range(simulations):
        brownian = 0.0
        offset = simulation * steps
        for step in range(steps):
            brownian += sqrt_dt * normals[offset + step]
        terminal_price = s0 * math.exp(drift + volatility * brownian)
        payoffs.append(max(terminal_price - strike, 0.0))

    total = 0.0
    for payoff in payoffs:
        total += payoff
    result = (total / simulations) * math.exp(-rate * maturity)
    return result if math.isfinite(result) else None


def expected_output(
    values: Sequence[int | float] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, list[float]]:
    """Model input validation followed by output-buffer validation."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, []
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, []
    if input_length is not None and (
        type(input_length) is not int or input_length < 0
    ):
        return INVALID_RESULT, []
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, []
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, []

    result = expected_result(values)
    if result is None:
        return INVALID_RESULT, []
    if output_is_null or (output_capacity is not None and output_capacity < 1):
        return OUTPUT_ERROR, []
    return 1, [result]
