"""Shared independent oracle for the eight pinned R risk-metrics methods."""

from __future__ import annotations

from collections.abc import Sequence
import math
from statistics import NormalDist

INVALID_RESULT = -1
OUTPUT_ERROR = -2
ABSOLUTE_TOLERANCE = 1e-10
RELATIVE_TOLERANCE = 1e-10
MIN_PORTFOLIO_VALUE = 100.0
MAX_PORTFOLIO_VALUE = 1_000_000.0
MIN_CONFIDENCE = 0.5
MAX_CONFIDENCE = 0.95
MIN_TIME_HORIZON = 1.0
MAX_TIME_HORIZON = 10.0
MIN_RETURN = -0.25
MAX_RETURN = 0.25
MIN_RETURN_COUNT = 20
MAX_RETURN_COUNT = 64
MIN_SIMULATION_COUNT = 20
MAX_SIMULATION_COUNT = 128
MIN_STANDARD_NORMAL = -3.0
MAX_STANDARD_NORMAL = 3.0
MAX_UPDATE_RETURN_COUNT = 60
MAX_PARSEABLE_INPUT_LENGTH = 198
MAX_OUTPUT_ELEMENTS = 64

ALGORITHM_NAMES = (
    "historical_var",
    "parametric_var",
    "monte_carlo_var",
    "historical_expected_shortfall",
    "parametric_expected_shortfall",
    "monte_carlo_expected_shortfall",
    "generate_risk_report",
    "update_returns",
)

MAX_PARSEABLE_INPUT_LENGTH_BY_ALGORITHM = {
    **{algorithm: 4 + MAX_RETURN_COUNT + 1 for algorithm in (
        "historical_var",
        "parametric_var",
        "historical_expected_shortfall",
        "parametric_expected_shortfall",
        "generate_risk_report",
    )},
    "monte_carlo_var": 5 + MAX_RETURN_COUNT + MAX_SIMULATION_COUNT + 1,
    "monte_carlo_expected_shortfall": 5 + MAX_RETURN_COUNT + MAX_SIMULATION_COUNT + 1,
    "update_returns": 1 + MAX_UPDATE_RETURN_COUNT + 1,
}


def _finite_values(values: object) -> list[float] | None:
    if not isinstance(values, (list, tuple)):
        return None
    result: list[float] = []
    for value in values:
        if type(value) not in (int, float):
            return None
        try:
            number = float(value)
        except (OverflowError, ValueError):
            return None
        if not math.isfinite(number):
            return None
        result.append(number)
    return result


def _integer(value: float) -> int | None:
    if not value.is_integer():
        return None
    return int(value)


def _mean(values: Sequence[float]) -> float:
    return math.fsum(values) / len(values)


def _sd(values: Sequence[float], mean: float | None = None) -> float:
    center = _mean(values) if mean is None else mean
    return math.sqrt(math.fsum((value - center) ** 2 for value in values) / (len(values) - 1))


def _common_risk_input(values: object, *, needs_tail_index: bool) -> tuple[float, float, float, list[float]] | None:
    raw = _finite_values(values)
    if raw is None or not 4 + MIN_RETURN_COUNT <= len(raw) <= 4 + MAX_RETURN_COUNT + 1:
        return None
    portfolio, confidence, horizon = raw[:3]
    count = _integer(raw[3])
    if count is None or not MIN_RETURN_COUNT <= count <= MAX_RETURN_COUNT:
        return None
    if len(raw) != 4 + count:
        return None
    if not MIN_PORTFOLIO_VALUE <= portfolio <= MAX_PORTFOLIO_VALUE:
        return None
    if not MIN_CONFIDENCE <= confidence <= MAX_CONFIDENCE:
        return None
    if not MIN_TIME_HORIZON <= horizon <= MAX_TIME_HORIZON:
        return None
    returns = raw[4:]
    if any(not MIN_RETURN <= value <= MAX_RETURN for value in returns):
        return None
    if needs_tail_index and math.floor((1.0 - confidence) * count) < 1:
        return None
    return portfolio, confidence, horizon, returns


def _tail_index(confidence: float, count: int) -> int:
    """Return the source's one-based tail index as a zero-based Python count."""
    return math.floor((1.0 - confidence) * count)


def _historical_var(portfolio: float, confidence: float, horizon: float, returns: Sequence[float]) -> float:
    index = _tail_index(confidence, len(returns))
    return -sorted(returns)[index - 1] * portfolio * math.sqrt(horizon)


def _historical_es(portfolio: float, confidence: float, horizon: float, returns: Sequence[float]) -> float:
    index = _tail_index(confidence, len(returns))
    tail = sorted(returns)[:index]
    return -_mean(tail) * portfolio * math.sqrt(horizon)


def _parametric(portfolio: float, confidence: float, horizon: float, returns: Sequence[float], *, es: bool) -> float:
    mean = _mean(returns)
    volatility = _sd(returns, mean)
    z_score = NormalDist().inv_cdf(confidence)
    if es:
        density = math.exp(-0.5 * z_score * z_score) / math.sqrt(2.0 * math.pi)
        multiplier = density / (1.0 - confidence)
    else:
        multiplier = z_score
    return portfolio * (multiplier * volatility - mean) * math.sqrt(horizon)


def _monte_carlo_input(values: object) -> tuple[float, float, float, int, int, list[float], list[float]] | None:
    raw = _finite_values(values)
    if raw is None or len(raw) < 5 + MIN_RETURN_COUNT + MIN_SIMULATION_COUNT or len(raw) > 5 + MAX_RETURN_COUNT + MAX_SIMULATION_COUNT + 1:
        return None
    portfolio, confidence, horizon = raw[:3]
    simulation_count = _integer(raw[3])
    return_count = _integer(raw[4])
    if simulation_count is None or not MIN_SIMULATION_COUNT <= simulation_count <= MAX_SIMULATION_COUNT:
        return None
    if return_count is None or not MIN_RETURN_COUNT <= return_count <= MAX_RETURN_COUNT:
        return None
    if len(raw) != 5 + return_count + simulation_count:
        return None
    if not MIN_PORTFOLIO_VALUE <= portfolio <= MAX_PORTFOLIO_VALUE:
        return None
    if not MIN_CONFIDENCE <= confidence <= MAX_CONFIDENCE:
        return None
    if not MIN_TIME_HORIZON <= horizon <= MAX_TIME_HORIZON:
        return None
    returns = raw[5 : 5 + return_count]
    if any(not MIN_RETURN <= value <= MAX_RETURN for value in returns):
        return None
    if _sd(returns) == 0.0:
        return None
    draws = raw[5 + return_count :]
    if any(not MIN_STANDARD_NORMAL <= value <= MAX_STANDARD_NORMAL for value in draws):
        return None
    if math.floor((1.0 - confidence) * simulation_count) < 1:
        return None
    return portfolio, confidence, horizon, simulation_count, return_count, returns, draws


def _update_input(values: object) -> list[float] | None:
    raw = _finite_values(values)
    if raw is None or not 1 + 2 <= len(raw) <= 1 + MAX_UPDATE_RETURN_COUNT + 1:
        return None
    count = _integer(raw[0])
    if count is None or not 2 <= count <= MAX_UPDATE_RETURN_COUNT or len(raw) != 1 + count:
        return None
    returns = raw[1:]
    if any(not MIN_RETURN <= value <= MAX_RETURN for value in returns):
        return None
    if _sd(returns) == 0.0:
        return None
    return returns


def expected_result(algorithm: str, input_values: Sequence[int | float] | None) -> list[float] | None:
    """Return the method's bounded output projection, or None for invalid input."""
    if algorithm not in ALGORITHM_NAMES:
        return None

    if algorithm in ("monte_carlo_var", "monte_carlo_expected_shortfall"):
        parsed = _monte_carlo_input(input_values)
        if parsed is None:
            return None
        portfolio, confidence, horizon, simulation_count, return_count, returns, draws = parsed
        # The wrapper injects the standardized normal stream and preserves the
        # source rnorm transform in order: mean + sample_sd * z_i.
        mean = _mean(returns)
        volatility = _sd(returns, mean)
        simulated = [mean + volatility * draw for draw in draws]
        index = _tail_index(confidence, simulation_count)
        if algorithm == "monte_carlo_var":
            value = -sorted(simulated)[index - 1] * portfolio * math.sqrt(horizon)
        else:
            value = -_mean(sorted(simulated)[:index]) * portfolio * math.sqrt(horizon)
        return [value] if math.isfinite(value) else None

    if algorithm == "update_returns":
        returns = _update_input(input_values)
        if returns is None:
            return None
        mean = _mean(returns)
        volatility = _sd(returns, mean)
        parametric_var_after_update = _parametric(100_000.0, 0.95, 1.0, returns, es=False)
        result = [*returns, mean, volatility, parametric_var_after_update]
        return result if len(result) <= MAX_OUTPUT_ELEMENTS and all(map(math.isfinite, result)) else None

    parsed = _common_risk_input(
        input_values,
        needs_tail_index=algorithm in (
            "historical_var",
            "historical_expected_shortfall",
            "generate_risk_report",
        ),
    )
    if parsed is None:
        return None
    portfolio, confidence, horizon, returns = parsed

    if algorithm == "historical_var":
        result = [_historical_var(portfolio, confidence, horizon, returns)]
    elif algorithm == "parametric_var":
        result = [_parametric(portfolio, confidence, horizon, returns, es=False)]
    elif algorithm == "historical_expected_shortfall":
        result = [_historical_es(portfolio, confidence, horizon, returns)]
    elif algorithm == "parametric_expected_shortfall":
        result = [_parametric(portfolio, confidence, horizon, returns, es=True)]
    elif algorithm == "generate_risk_report":
        mean = _mean(returns)
        volatility = _sd(returns, mean)
        if volatility == 0.0:
            return None
        m3 = math.fsum((value - mean) ** 3 for value in returns) / len(returns)
        m4 = math.fsum((value - mean) ** 4 for value in returns) / len(returns)
        skewness = m3 / (volatility**3)
        excess_kurtosis = m4 / (volatility**4) - 3.0
        result = [
            _historical_var(portfolio, confidence, horizon, returns),
            _historical_es(portfolio, confidence, horizon, returns),
            _parametric(portfolio, confidence, horizon, returns, es=False),
            _parametric(portfolio, confidence, horizon, returns, es=True),
            mean,
            volatility,
            skewness,
            excess_kurtosis,
        ]
    else:
        return None

    return result if all(map(math.isfinite, result)) else None


def expected_output(
    algorithm: str,
    input_values: Sequence[int | float] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, list[float]]:
    """Model input and output-buffer checks for the float64 slice ABI."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, []
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return INVALID_RESULT, []
    if input_length is not None and (type(input_length) is not int or input_length < 0):
        return INVALID_RESULT, []
    if input_is_null or not isinstance(input_values, (list, tuple)):
        return INVALID_RESULT, []
    if input_length is not None and input_length != len(input_values):
        return INVALID_RESULT, []

    result = expected_result(algorithm, input_values)
    if result is None:
        return INVALID_RESULT, []
    if output_is_null or (output_capacity is not None and output_capacity < len(result)):
        return OUTPUT_ERROR, []
    return len(result), result


def expected_output_for(algorithm: str):
    """Build the ABI-oracle function expected by the float64 slice runner."""
    def _expected(
        input_values: Sequence[int | float] | None,
        output_capacity: int | None = None,
        output_is_null: bool = False,
        input_is_null: bool = False,
        input_length: int | None = None,
    ) -> tuple[int, list[float]]:
        return expected_output(
            algorithm,
            input_values,
            output_capacity,
            output_is_null,
            input_is_null,
            input_length,
        )
    return _expected
