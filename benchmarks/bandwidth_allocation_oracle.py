"""Reference for TheAlgorithms/Java's bounded bandwidth allocation routine."""

from __future__ import annotations

MAX_USERS = 64
MAX_BANDWIDTH = 100_000
MAX_DEMAND = 1_000
MAX_VALUE = 10_000


def expected_result(values: list[int]) -> int:
    if (not isinstance(values, list) or len(values) < 2
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1
    bandwidth, count = values[:2]
    if (not 0 <= bandwidth <= MAX_BANDWIDTH or not 0 <= count <= MAX_USERS
            or len(values) != 2 + 2 * count):
        return -1
    demands = values[2:2 + count]
    gains = values[2 + count:]
    if (any(not 1 <= demand <= MAX_DEMAND for demand in demands)
            or any(not 0 <= gain <= MAX_VALUE for gain in gains)):
        return -1

    order = sorted(range(count), key=lambda index: gains[index] / demands[index], reverse=True)
    remaining = bandwidth
    total = 0
    for index in order:
        if remaining >= demands[index]:
            total += gains[index]
            remaining -= demands[index]
        else:
            total += int((gains[index] / demands[index]) * remaining)
            break
    return total
