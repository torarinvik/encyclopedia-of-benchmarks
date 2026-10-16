package greedy_item_selection_by_value

import "core:c"

@(export)
greedy_item_selection_by_value :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 2 || length > 18 do return -1
	capacity := values[0]
	count_value := values[1]
	if capacity < 0 || capacity > 1_000_000 || count_value < 0 || count_value > 8 do return -1
	count := int(count_value)
	if length != c.size_t(2 + 2 * count) do return -1
	item_values: [8]i64
	weights: [8]i64
	order: [8]int
	for index := 0; index < count; index += 1 {
		item_values[index] = values[2 + index]
		weights[index] = values[2 + count + index]
		if item_values[index] < 0 || item_values[index] > 1_000_000 || weights[index] < 1 || weights[index] > 1_000_000 do return -1
		order[index] = index
	}
	for index := 1; index < count; index += 1 {
		current := order[index]
		position := index
		for position > 0 && item_values[order[position - 1]] < item_values[current] {
			order[position] = order[position - 1]
			position -= 1
		}
		order[position] = current
	}
	total_weight: i64 = 0
	total_value: i64 = 0
	sequence: u64 = 0
	selected := 0
	for index := 0; index < count; index += 1 {
		item := order[index]
		if total_weight + weights[item] <= capacity {
			sequence |= u64(item + 1) << (4 * selected)
			selected += 1
			total_weight += weights[item]
			total_value += item_values[item]
		}
	}
	return i64((u64(total_value) << 36) | (u64(selected) << 32) | sequence)
}
