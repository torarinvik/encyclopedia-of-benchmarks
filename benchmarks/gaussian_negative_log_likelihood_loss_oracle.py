"""Oracle for the bounded Gaussian negative log-likelihood loss workload."""

from __future__ import annotations

import math

MAX_COUNT = 256
MAX_INPUT_LENGTH = 1 + 3 * MAX_COUNT
TARGET_SCALE = 1_000_000
VARIANCE_SCALE = 1_000_000_000
MAX_TARGET_MICRO = 1_000_000
MIN_VARIANCE_NANO = 1
MAX_VARIANCE_NANO = 1_000_000_000
EPSILON = 1e-6
INVALID_RESULT = -1e300
I64_MIN = -(2**63)
I64_MAX = 2**63 - 1


def expected_result(values: list[int]) -> float:
    if (
        not isinstance(values, list)
        or len(values) < 4
        or len(values) > MAX_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return INVALID_RESULT

    count = values[0]
    if not 1 <= count <= MAX_COUNT or len(values) != 1 + 3 * count:
        return INVALID_RESULT

    targets = values[1 : 1 + count]
    expectations = values[1 + count : 1 + 2 * count]
    variances = values[1 + 2 * count :]
    if any(abs(value) > MAX_TARGET_MICRO for value in (*targets, *expectations)):
        return INVALID_RESULT
    if any(not MIN_VARIANCE_NANO <= value <= MAX_VARIANCE_NANO for value in variances):
        return INVALID_RESULT

    total = 0.0
    for target_micro, expectation_micro, variance_nano in zip(
        targets, expectations, variances
    ):
        target = target_micro / TARGET_SCALE
        expectation = expectation_micro / TARGET_SCALE
        variance = max(variance_nano / VARIANCE_SCALE, EPSILON)
        residual = target - expectation
        total += 0.5 * math.log(variance) + 0.5 * ((residual * residual) / variance)
    return total / count
