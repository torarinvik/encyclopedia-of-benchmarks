"""Oracle adapter for the pinned R historical VaR method."""

from risk_metrics_oracle import expected_output_for, expected_result as _expected_result

ALGORITHM = "historical_var"
expected_output = expected_output_for(ALGORITHM)


def expected_result(input_values):
    return _expected_result(ALGORITHM, input_values)
