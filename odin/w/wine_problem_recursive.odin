package wine_problem_recursive

import "core:c"

MAX_ITEMS :: 14
MAX_PRICE :: i64 = 1_000_000

solve :: proc "contextless" (prices: [^]i64, count, first, last: int) -> i64 {
	year := i64(count - (last - first + 1) + 1)
	if first == last do return prices[first] * year
	sell_first := prices[first] * year + solve(prices, count, first + 1, last)
	sell_last := prices[last] * year + solve(prices, count, first, last - 1)
	if sell_first > sell_last do return sell_first
	return sell_last
}

@(export)
wine_problem_recursive :: proc "c" (prices: [^]i64, length: c.size_t) -> i64 {
	if prices == nil || length == 0 || length > c.size_t(MAX_ITEMS) do return -1
	for index := 0; index < int(length); index += 1 {
		if prices[index] < 0 || prices[index] > MAX_PRICE do return -1
	}
	return solve(prices, int(length), 0, int(length)-1)
}
