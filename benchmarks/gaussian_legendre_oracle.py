"""Reference for the pinned order-1-through-5 Gauss-Legendre tables."""

from __future__ import annotations

import math
from collections.abc import Sequence

MAX_INPUT_LENGTH = 7
INVALID_RESULT = -1e300
MAX_ORDER = 5
MAX_INTERVAL_MILLI = 5000
MAX_COEFFICIENT_MILLI = 10000

NODES = (
    (0.0,),
    (-0.5773502692, 0.5773502692),
    (-0.7745966692, 0.0, 0.7745966692),
    (-0.8611363116, -0.3399810436, 0.3399810436, 0.8611363116),
    (-0.9061798459, -0.5384693101, 0.0, 0.5384693101, 0.9061798459),
)
WEIGHTS = (
    (2.0,),
    (1.0, 1.0),
    (0.5555555556, 0.8888888889, 0.5555555556),
    (0.3478548451, 0.6521451549, 0.6521451549, 0.3478548451),
    (0.2369268851, 0.4786286705, 0.5688888889, 0.4786286705, 0.2369268851),
)


def expected_result(values: Sequence[int]) -> float:
    if (not isinstance(values, (list, tuple)) or len(values) != MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return INVALID_RESULT
    order, a_milli, b_milli, *coefficient_milli = values
    if not 1 <= order <= MAX_ORDER:
        return INVALID_RESULT
    if abs(a_milli) > MAX_INTERVAL_MILLI or abs(b_milli) > MAX_INTERVAL_MILLI:
        return INVALID_RESULT
    if any(abs(value) > MAX_COEFFICIENT_MILLI for value in coefficient_milli):
        return INVALID_RESULT

    a = a_milli / 1000.0
    b = b_milli / 1000.0
    c0, c1, c2, c3 = (value / 1000.0 for value in coefficient_milli)
    weighted_sum = 0.0
    for node, weight in zip(NODES[order - 1], WEIGHTS[order - 1]):
        x = (b + a) / 2.0 + (b - a) * node / 2.0
        x2 = x * x
        x3 = x2 * x
        function_value = c0 + c1 * x + c2 * x2 + c3 * x3
        weighted_sum += weight * function_value
    return weighted_sum * (b - a) / 2.0
