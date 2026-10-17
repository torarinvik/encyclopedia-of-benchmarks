"""Oracle for the bounded Go ternary maximum/minimum routines."""

from __future__ import annotations

MAX_INPUT_LENGTH = 6  # admit one trailing value for malformed-input coverage
MAX_CALLS = 64
INVALID_RESULT = -1.0e300


def _objective(operation: int, x: float) -> float:
    if operation == 0:
        delta = x - 1.0
        return -(delta * delta)
    delta = x + 1.0
    return delta * delta


def expected_result(values: list[int]) -> float:
    if (not isinstance(values, list) or len(values) != 5
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT

    operation, a_milli, b_milli, epsilon_micro, max_calls = values
    if (operation not in (0, 1)
            or not -1_000_000 <= a_milli <= b_milli <= 1_000_000
            or not 1 <= epsilon_micro <= 1_000_000
            or not 1 <= max_calls <= MAX_CALLS):
        return INVALID_RESULT

    a = a_milli / 1000.0
    b = b_milli / 1000.0
    epsilon = epsilon_micro / 1_000_000.0

    def search(left_bound: float, right_bound: float, frame: int) -> float:
        width = left_bound - right_bound
        if width < 0.0:
            width = -width
        if width <= epsilon:
            return _objective(operation, (left_bound + right_bound) / 2.0)

        left = (2.0 * left_bound + right_bound) / 3.0
        right = (left_bound + 2.0 * right_bound) / 3.0
        left_value = _objective(operation, left)
        right_value = _objective(operation, right)
        take_left = left_value < right_value if operation == 0 else left_value > right_value
        if frame >= max_calls:
            return INVALID_RESULT
        if take_left:
            return search(left, right_bound, frame + 1)
        return search(left_bound, right, frame + 1)

    return search(a, b, 1)
