package best_time_to_buy_and_sell_stock

import "core:c"

// Maximum profit from one buy followed by one sell.
@(export)
best_time_to_buy_and_sell_stock :: proc "c" (prices: [^]i64, length: c.size_t) -> i64 {
	if length > 4096 do return -1
	if length == 0 do return 0
	minimum := prices[0]
	best := i64(0)
	for day: c.size_t = 0; day < length; day += 1 {
		price := prices[day]
		if price < 0 || price > 1_000_000_000 do return -1
		minimum = min(minimum, price)
		best = max(best, price - minimum)
	}
	return best
}
