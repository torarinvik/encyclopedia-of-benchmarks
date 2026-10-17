"""Oracle for bounded deterministic forward_propagation."""
import math
INVALID_RESULT = -1.0e300
MIN_EXPECTED = 0
MAX_EXPECTED = 100
MIN_INITIAL_WEIGHT = 1
MAX_INITIAL_WEIGHT = 199
MIN_PROPAGATIONS = 1
MAX_PROPAGATIONS = 65_536
MAX_INPUT_LENGTH = 3
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values):
    if (not isinstance(values, (list, tuple)) or len(values) != MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT
    expected, weight, count = values
    if (not MIN_EXPECTED <= expected <= MAX_EXPECTED
            or not MIN_INITIAL_WEIGHT <= weight <= MAX_INITIAL_WEIGHT
            or weight % 2 != 1
            or not MIN_PROPAGATIONS <= count <= MAX_PROPAGATIONS):
        return INVALID_RESULT
    layer = 0.0
    for _ in range(count):
        layer = 1.0 / (1.0 + math.exp(-0.02 * weight))
        error = expected / 100.0 - layer
        delta = error * layer * (1.0 - layer)
        weight += 0.02 * delta
    return layer * 100.0
