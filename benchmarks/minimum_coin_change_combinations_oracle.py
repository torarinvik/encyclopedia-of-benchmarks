"""Independent oracle for the bounded unordered coin-combinations contract."""

INVALID_RESULT = -1


def expected_result(values: list[int]) -> int:
    """Return the number of unlimited unordered combinations, or -1 if invalid."""
    if not isinstance(values, list) or len(values) < 2 or len(values) > 34:
        return INVALID_RESULT
    if any(type(value) is not int for value in values):
        return INVALID_RESULT

    target, count = values[0], values[1]
    if not -64 <= target <= 64 or not 0 <= count <= 32:
        return INVALID_RESULT
    if len(values) != count + 2:
        return INVALID_RESULT

    denominations = values[2:]
    if any(not 1 <= coin <= 64 for coin in denominations):
        return INVALID_RESULT
    if any(denominations[index - 1] >= denominations[index]
           for index in range(1, len(denominations))):
        return INVALID_RESULT

    if target < 0:
        return 0
    ways = [0] * (target + 1)
    ways[0] = 1
    for coin in denominations:
        for amount in range(coin, target + 1):
            ways[amount] += ways[amount - coin]
    return ways[target]
