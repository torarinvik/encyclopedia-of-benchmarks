"""Independent oracle for the bounded two-coordinate Gauss search."""

from __future__ import annotations

import math

MAX_INPUT_LENGTH = 7
MAX_ITERATIONS = 256


def _objective(x1: float, x2: float, target1: float, target2: float) -> float:
    return -((x1 - target1) ** 2 + (x2 - target2) ** 2)


def expected_result(values: list[float] | tuple[float, ...]) -> list[float] | None:
    if (not isinstance(values, (list, tuple)) or len(values) != MAX_INPUT_LENGTH
            or any(type(value) not in (int, float) or not math.isfinite(float(value))
                   for value in values)):
        return None
    factor, step, epsilon, x1, x2, target1, target2 = map(float, values)
    if (factor not in (2.0, 3.0, 4.0) or not 0.25 <= step <= 4.0
            or not 1e-6 <= epsilon <= 2.0
            or any(not -8.0 <= coordinate <= 8.0
                   for coordinate in (x1, x2, target1, target2))):
        return None

    error = 1.0
    iteration = 0
    while abs(error) > epsilon and iteration < MAX_ITERATIONS:
        current = _objective(x1, x2, target1, target2)
        candidates = (
            _objective(x1, x2 - step, target1, target2),
            _objective(x1, x2 + step, target1, target2),
            _objective(x1 - step, x2, target1, target2),
            _objective(x1 + step, x2, target1, target2),
        )
        choice = max(range(4), key=candidates.__getitem__)
        error = candidates[choice] - current
        if choice == 0:
            x2 -= step
        elif choice == 1:
            x2 += step
        elif choice == 2:
            x1 -= step
        else:
            x1 += step
        step /= factor
        iteration += 1
    if abs(error) > epsilon:
        return None
    return [x1, x2]
