"""Independent capacity-indexed subset-sum DP oracle."""

from __future__ import annotations

MAX_ITEMS = 32
MAX_TARGET = 256
MAX_WEIGHT = 12
MAX_VALID_INPUT_LENGTH = 34
MAX_PARSEABLE_INPUT_LENGTH = 35
WORKSPACE_BYTES = 1024


def expected_result(values, input_is_null=False, input_length=None):
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1
    if (len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return -1
    n, target = values[:2]
    if not 0 <= n <= MAX_ITEMS or not 0 <= target <= MAX_TARGET:
        return -1
    if len(values) != n + 2:
        return -1
    weights = values[2:]
    if any(not 1 <= weight <= MAX_WEIGHT for weight in weights):
        return -1

    reachable = [False] * (target + 1)
    reachable[0] = True
    for weight in weights:
        for mass in range(target, weight - 1, -1):
            if reachable[mass - weight]:
                reachable[mass] = True
    for mass in range(target, -1, -1):
        if reachable[mass]:
            return mass
    return 0
