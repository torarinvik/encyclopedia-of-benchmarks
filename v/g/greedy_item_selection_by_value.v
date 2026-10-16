module greedy_item_selection_by_value

const max_items = 8

@[export: 'greedy_item_selection_by_value']
pub fn greedy_item_selection_by_value(values &i64, length usize) i64 {
	if unsafe { values == nil } || length < 2 || length > 18 { return -1 }
	capacity := unsafe { values[0] }
	count_value := unsafe { values[1] }
	if capacity < 0 || capacity > 1_000_000 || count_value < 0 || count_value > max_items || length != usize(2 + 2 * count_value) { return -1 }
	count := int(count_value)
	mut item_values := [max_items]i64{}
	mut weights := [max_items]i64{}
	mut order := [max_items]int{}
	for index in 0 .. count {
		item_values[index] = unsafe { values[2 + index] }
		weights[index] = unsafe { values[2 + count + index] }
		if item_values[index] < 0 || item_values[index] > 1_000_000 || weights[index] < 1 || weights[index] > 1_000_000 { return -1 }
		order[index] = index
	}
	for index in 1 .. count {
		current := order[index]
		mut position := index
		for position > 0 && item_values[order[position - 1]] < item_values[current] {
			order[position] = order[position - 1]
			position--
		}
		order[position] = current
	}
	mut total_weight := i64(0)
	mut total_value := i64(0)
	mut sequence := u64(0)
	mut selected := 0
	for index in 0 .. count {
		item := order[index]
		if total_weight + weights[item] <= capacity {
			sequence |= u64(item + 1) << (4 * selected)
			selected++
			total_weight += weights[item]
			total_value += item_values[item]
		}
	}
	return i64((u64(total_value) << 36) | (u64(selected) << 32) | sequence)
}
