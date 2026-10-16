"""Oracle for the bounded C# Maclaurin error-threshold overloads."""
from __future__ import annotations

MAX_INPUT_LENGTH = 3
INVALID_RESULT = -1.0e300


def _factorial(n: int) -> int:
    value = 1
    for i in range(2, n + 1):
        value *= i
    return value


def _term(mode: int, x: float, i: int) -> float:
    if mode == 0:
        return x**i / _factorial(i)
    if mode == 1:
        exponent = 2 * i + 1
        return ((-1.0) ** i / _factorial(exponent)) * x**exponent
    exponent = 2 * i
    return ((-1.0) ** i / _factorial(exponent)) * x**exponent


def expected_result(values):
    if (not isinstance(values, (list, tuple)) or len(values) != 3
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT
    mode, x_milli, error_milli = values
    if mode not in (0, 1, 2) or not -2000 <= x_milli <= 2000 or not 1 <= error_milli <= 250:
        return INVALID_RESULT
    x = x_milli / 1000.0
    error = error_milli / 1000.0
    term_coefficient = 0.0
    result = 0.0
    i = 0
    while True:
        result += term_coefficient
        term_coefficient = _term(mode, x, i)
        i += 1
        if abs(term_coefficient) <= error:
            return result
        if i > 32:  # unreachable on the bounded input domain
            return INVALID_RESULT
