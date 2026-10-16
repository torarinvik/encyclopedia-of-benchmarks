"""Independent bottom-up oracle for top-down memoized wine selling."""

MAX_ITEMS = 64
MIN_PRICE = 1
MAX_PRICE = 1_000_000


def expected_result(prices: list[int]) -> int:
    if not 1 <= len(prices) <= MAX_ITEMS:
        return -1
    if any(not MIN_PRICE <= price <= MAX_PRICE for price in prices):
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
                best[first][last] = max(
                    prices[first] * year + best[first + 1][last],
                    prices[last] * year + best[first][last - 1],
                )
    return best[0][count - 1]
