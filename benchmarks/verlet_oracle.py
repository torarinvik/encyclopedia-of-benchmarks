"""Independent oracle for a bounded one-dimensional Verlet recurrence."""

from __future__ import annotations

import math

MAX_INPUT_LENGTH = 4
MAX_STEPS = 32
STEP_SIZES = (1.0 / 256.0, 1.0 / 128.0, 1.0 / 64.0,
              1.0 / 32.0, 1.0 / 16.0)


def expected_result(values: list[float] | tuple[float, ...]) -> list[float] | None:
    if (not isinstance(values, (list, tuple)) or len(values) != MAX_INPUT_LENGTH
            or any(type(value) not in (int, float) or not math.isfinite(float(value))
                   for value in values)):
        return None

    step_count, x0, velocity0, dt_code = map(float, values)
    if (not step_count.is_integer() or not 2 <= step_count <= MAX_STEPS
            or not -1.0 <= x0 <= 1.0 or not -1.0 <= velocity0 <= 1.0
            or not dt_code.is_integer() or not 0 <= dt_code < len(STEP_SIZES)):
        return None

    n = int(step_count)
    dt = STEP_SIZES[int(dt_code)]
    dt_squared = dt * dt
    positions = [x0]
    positions.append(x0 + velocity0 * dt + 0.5 * (-x0) * dt_squared)
    for index in range(1, n - 1):
        positions.append(2.0 * positions[index] - positions[index - 1]
                         + (-positions[index]) * dt_squared)
    times = [index * dt for index in range(n)]
    return positions + times
