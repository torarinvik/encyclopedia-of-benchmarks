"""Oracle for the pinned fixed-step Runge-Kutta-Fehlberg 4(5) routine."""

from runge_kutta_common_oracle import INVALID_RESULT, MAX_INPUT_LENGTH
from runge_kutta_common_oracle import expected_result_for


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    return expected_result_for(values, "fehlberg45")
