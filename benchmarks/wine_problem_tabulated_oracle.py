"""Independent top-down oracle for tabulated wine selling."""

from functools import lru_cache

MAX_ITEMS = 64
MAX_PRICE = 1_000_000


def expected_result(prices: list[int]) -> int:
    if not 1 <= len(prices) <= MAX_ITEMS:
        return -1
    if any(not 0 <= price <= MAX_PRICE for price in prices):
        return -1
    count = len(prices)

    @lru_cache(maxsize=None)
    def solve(first: int, last: int) -> int:
        year = count - (last - first + 1) + 1
        if first == last:
            return prices[first] * year
        return max(
            prices[first] * year + solve(first + 1, last),
            prices[last] * year + solve(first, last - 1),
        )

    return solve(0, count - 1)
