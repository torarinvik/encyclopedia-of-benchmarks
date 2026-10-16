"""Source-ordered oracle for the bounded Python Gaussian density workload."""

import math

INVALID_RESULT = -1e300


def expected_result(values: list[int]) -> float:
    if (len(values) != 3
            or not -100 <= values[0] <= 100
            or not -100 <= values[1] <= 100
            or not 1 <= values[2] <= 100):
        return INVALID_RESULT
    x, mu, sigma = values
    return (1 / math.sqrt(2 * math.pi * sigma ** 2)
            * math.exp(-((x - mu) ** 2) / (2 * sigma ** 2)))
