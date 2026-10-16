"""Bounded oracle for the two pinned Python gas-station algorithms."""

from __future__ import annotations

MAX_STATIONS = 128
MAX_INPUT_LENGTH = 2 * MAX_STATIONS + 1
MAX_AMOUNT = 1_000_000


def expected_result(values: tuple[int, ...] | list[int]) -> int:
    if (not isinstance(values, (tuple, list)) or not values
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -2
    count = values[0]
    if not 0 <= count <= MAX_STATIONS or len(values) != 2 * count + 1:
        return -2
    gas = values[1:1 + count]
    costs = values[1 + count:]
    if any(not 0 <= amount <= MAX_AMOUNT for amount in (*gas, *costs)):
        return -2

    candidate = 0
    running_net = 0
    total_net = 0
    for index, (available, cost) in enumerate(zip(gas, costs)):
        net = available - cost
        total_net += net
        running_net += net
        if running_net < 0:
            candidate = index + 1
            running_net = 0
    return -1 if total_net < 0 else candidate
