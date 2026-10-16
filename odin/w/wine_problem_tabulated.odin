package wine_problem_tabulated

import "core:c"

MAX_ITEMS :: 64
MAX_PRICE :: i64 = 1_000_000

@(export)
wine_problem_tabulated :: proc "c" (prices: [^]i64, length: c.size_t) -> i64 {
	if prices == nil || length == 0 || length > c.size_t(MAX_ITEMS) do return -1
	for index := 0; index < int(length); index += 1 {
		if prices[index] < 0 || prices[index] > MAX_PRICE do return -1
	}
	var table: [MAX_ITEMS * MAX_ITEMS]i64
	for width := 1; width <= int(length); width += 1 {
		year := i64(int(length) - width + 1)
		for first := 0; first + width <= int(length); first += 1 {
			last := first + width - 1
			slot := first * MAX_ITEMS + last
			if first == last {
				table[slot] = prices[first] * year
			} else {
				sell_first := prices[first] * year + table[(first+1)*MAX_ITEMS+last]
				sell_last := prices[last] * year + table[first*MAX_ITEMS+last-1]
				if sell_first > sell_last { table[slot] = sell_first } else { table[slot] = sell_last }
			}
		}
	}
	return table[int(length)-1]
}
