"""Source-ordered oracle for the bounded Maclaurin sine/cosine workload."""

import math

INVALID_RESULT = -1e300


def expected_result(values: list[int]) -> float:
    if (len(values) != 3 or values[0] not in (0, 1)
            or not -10 <= values[1] <= 10
            or not 1 <= values[2] <= 30):
        return INVALID_RESULT
    mode, theta_value, accuracy = values
    theta = float(theta_value)
    div = theta // (2 * math.pi)
    theta -= 2 * div * math.pi
    if mode == 0:
        return sum((-1) ** r * theta ** (2 * r + 1) / math.factorial(2 * r + 1)
                   for r in range(accuracy))
    return sum((-1) ** r * theta ** (2 * r) / math.factorial(2 * r)
               for r in range(accuracy))
