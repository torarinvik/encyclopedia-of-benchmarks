package wine_problem_memoized

import "core:c"

MAX_ITEMS :: 64
MAX_PRICE :: i64 = 1_000_000

solve :: proc "contextless" (prices: [^]i64, count, first, last: int, memo: [^]i64) -> i64 {
	slot := first * MAX_ITEMS + last
	year := i64(count - (last - first + 1) + 1)
	if first == last { memo[slot] = prices[first] * year; return memo[slot] }
	if memo[slot] != 0 do return memo[slot]
	sell_first := prices[first] * year + solve(prices, count, first + 1, last, memo)
	sell_last := prices[last] * year + solve(prices, count, first, last - 1, memo)
	if sell_first > sell_last { memo[slot] = sell_first } else { memo[slot] = sell_last }
	return memo[slot]
}

@(export)
wine_problem_memoized :: proc "c" (prices: [^]i64, length: c.size_t) -> i64 {
	if prices == nil || length == 0 || length > c.size_t(MAX_ITEMS) do return -1
	for index := 0; index < int(length); index += 1 {
		if prices[index] < 1 || prices[index] > MAX_PRICE do return -1
	}
	var memo: [MAX_ITEMS * MAX_ITEMS]i64
	for index := 0; index < MAX_ITEMS * MAX_ITEMS; index += 1 { memo[index] = 0 }
	return solve(prices, int(length), 0, int(length)-1, &memo[0])
}
