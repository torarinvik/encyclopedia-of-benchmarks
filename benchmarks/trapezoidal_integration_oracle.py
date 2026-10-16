"""Oracle for the bounded pinned Rust trapezoidal integrator."""

from __future__ import annotations

SCALE = 1_000_000
MAX_ENDPOINT_MICRO = 1_000_000
MAX_STEPS = 10_000
MAX_INPUT_LENGTH = 5  # admit one extra packed value for malformed-input coverage
INVALID_RESULT = -1.0e300


def expected_result(values: list[int]) -> float:
    if (not isinstance(values, list) or len(values) != 4
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT
    start_micro, end_micro, steps, function_id = values
    if (not -MAX_ENDPOINT_MICRO <= start_micro <= MAX_ENDPOINT_MICRO
            or not -MAX_ENDPOINT_MICRO <= end_micro <= MAX_ENDPOINT_MICRO
            or not 1 <= steps <= MAX_STEPS or function_id not in (0, 1)):
        return INVALID_RESULT

    start = start_micro / SCALE
    end = end_micro / SCALE
    delta = (end - start) / steps
    total = 0.0

    def sample(x: float) -> float:
        if function_id == 0:
            return x * x
        return x * x * x

    for index in range(steps):
        left = start + delta * index
        right = left + delta
        midpoint = (sample(left) + sample(right)) * 0.5
        total += midpoint * delta
    return total
