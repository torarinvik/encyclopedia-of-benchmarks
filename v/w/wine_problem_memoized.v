module wine_problem_memoized

const max_items = 64
const max_price = i64(1_000_000)

fn solve(prices &i64, count int, first int, last int, mut memo &i64) i64 {
	slot := first * max_items + last
	year := i64(count - (last - first + 1) + 1)
	if first == last {
		unsafe { memo[slot] = prices[first] * year }
		return unsafe { memo[slot] }
	}
	if unsafe { memo[slot] != 0 } { return unsafe { memo[slot] } }
	sell_first := unsafe { prices[first] } * year + solve(prices, count, first + 1, last, mut memo)
	sell_last := unsafe { prices[last] } * year + solve(prices, count, first, last - 1, mut memo)
	unsafe { memo[slot] = if sell_first > sell_last { sell_first } else { sell_last } }
	return unsafe { memo[slot] }
}

@[export: 'wine_problem_memoized']
pub fn wine_problem_memoized(prices &i64, length usize) i64 {
	if prices == nil || length == 0 || length > max_items { return -1 }
	for index in 0 .. int(length) {
		price := unsafe { prices[index] }
		if price < 1 || price > max_price { return -1 }
	}
	mut memo := [max_items * max_items]i64{}
	return solve(prices, int(length), 0, int(length) - 1, mut memo[0])
}
