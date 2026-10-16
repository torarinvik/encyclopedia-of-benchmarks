"""Independent bottom-up oracle for the bounded wine-selling recurrence."""

MAX_ITEMS = 14
MAX_PRICE = 1_000_000


def expected_result(prices: list[int]) -> int:
    if not 1 <= len(prices) <= MAX_ITEMS:
        return -1
    if any(not 0 <= price <= MAX_PRICE for price in prices):
        return -1

    count = len(prices)
    best = [[0] * count for _ in range(count)]
    for width in range(1, count + 1):
        year = count - width + 1
        for first in range(count - width + 1):
            last = first + width - 1
            if first == last:
                best[first][last] = prices[first] * year
            else:
                sell_first = prices[first] * year + best[first + 1][last]
                sell_last = prices[last] * year + best[first][last - 1]
                best[first][last] = max(sell_first, sell_last)
    return best[0][count - 1]
