module best_time_to_buy_and_sell_stock

// Maximum profit from one buy followed by one sell.
@[export: 'best_time_to_buy_and_sell_stock']
pub fn best_time_to_buy_and_sell_stock(prices &i64, length usize) i64 {
	if length > 4096 { return -1 }
	if length == 0 { return 0 }
	mut minimum := unsafe { prices[0] }
	mut best := i64(0)
	for day in 0 .. length {
		price := unsafe { prices[day] }
		if price < 0 || price > 1000000000 { return -1 }
		if price < minimum { minimum = price }
		profit := price - minimum
		if profit > best { best = profit }
	}
	return best
}
