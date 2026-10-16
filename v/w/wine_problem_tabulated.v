module wine_problem_tabulated

const max_items = 64
const max_price = i64(1_000_000)

@[export: 'wine_problem_tabulated']
pub fn wine_problem_tabulated(prices &i64, length usize) i64 {
	if prices == nil || length == 0 || length > max_items { return -1 }
	for index in 0 .. int(length) {
		price := unsafe { prices[index] }
		if price < 0 || price > max_price { return -1 }
	}
	mut table := [max_items * max_items]i64{}
	for width in 1 .. int(length) + 1 {
		year := i64(int(length) - width + 1)
		for first in 0 .. int(length) - width + 1 {
			last := first + width - 1
			slot := first * max_items + last
			if first == last {
				unsafe { table[slot] = prices[first] * year }
			} else {
				sell_first := unsafe { prices[first] } * year + table[(first + 1) * max_items + last]
				sell_last := unsafe { prices[last] } * year + table[first * max_items + last - 1]
				if sell_first > sell_last { table[slot] = sell_first } else { table[slot] = sell_last }
			}
		}
	}
	return table[int(length) - 1]
}
