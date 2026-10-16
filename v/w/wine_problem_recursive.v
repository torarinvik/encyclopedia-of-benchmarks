module wine_problem_recursive

const max_items = 14
const max_price = i64(1_000_000)

fn solve(prices &i64, count int, first int, last int) i64 {
	year := i64(count - (last - first + 1) + 1)
	if first == last { return unsafe { prices[first] } * year }
	sell_first := unsafe { prices[first] } * year + solve(prices, count, first + 1, last)
	sell_last := unsafe { prices[last] } * year + solve(prices, count, first, last - 1)
	if sell_first > sell_last { return sell_first }
	return sell_last
}

@[export: 'wine_problem_recursive']
pub fn wine_problem_recursive(prices &i64, length usize) i64 {
	if prices == nil || length == 0 || length > max_items { return -1 }
	for index in 0 .. int(length) {
		price := unsafe { prices[index] }
		if price < 0 || price > max_price { return -1 }
	}
	return solve(prices, int(length), 0, int(length) - 1)
}
