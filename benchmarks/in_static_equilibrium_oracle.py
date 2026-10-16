"""Independent packed-vector oracle for static torque equilibrium."""

from __future__ import annotations

MAX_N = 100
MAX_COMPONENT = 1000
MAX_INPUT_LENGTH = 1 + 4 * MAX_N
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1
    count = values[0]
    if not 1 <= count <= MAX_N or len(values) != 1 + 4 * count:
        return -1
    force_x = values[1:1 + count]
    force_y = values[1 + count:1 + 2 * count]
    location_x = values[1 + 2 * count:1 + 3 * count]
    location_y = values[1 + 3 * count:]
    if any(abs(component) > MAX_COMPONENT
           for component in (*force_x, *force_y, *location_x, *location_y)):
        return -1
    moment_sum = (sum(x * fy for x, fy in zip(location_x, force_y))
                  - sum(y * fx for y, fx in zip(location_y, force_x)))
    return int(abs(moment_sum) < 0.1)
